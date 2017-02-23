# rubocop: disable Rails/Output
module Gitlab
  # Checks if a set of migrations requires downtime or not.
  class EeCompatCheck
    CE_REPO = 'https://gitlab.com/gitlab-org/gitlab-ce.git'.freeze
    EE_REPO = 'https://gitlab.com/gitlab-org/gitlab-ee.git'.freeze
    CHECK_DIR = Rails.root.join('ee_compat_check')
    IGNORED_FILES_REGEX = /(VERSION|CHANGELOG\.md:\d+)/.freeze

    attr_reader :repo_dir, :patches_dir, :ce_repo, :ce_branch, :ee_branch_found
    attr_reader :failed_files

    def initialize(branch:, ce_repo: CE_REPO)
      @repo_dir = CHECK_DIR.join('repo')
      @patches_dir = CHECK_DIR.join('patches')
      @ce_branch = branch
      @ce_repo = ce_repo
    end

    def check
      ensure_ee_repo
      ensure_patches_dir

      generate_patch(ce_branch, ce_patch_full_path)

      Dir.chdir(repo_dir) do
        step("In the #{repo_dir} directory")

        status = catch(:halt_check) do
          ce_branch_compat_check!
          delete_ee_branches_locally!
          ee_branch_presence_check!
          ee_branch_compat_check!
        end

        delete_ee_branches_locally!

        if status.nil?
          true
        else
          false
        end
      end
    end

    private

    def ensure_ee_repo
      if Dir.exist?(repo_dir)
        step("#{repo_dir} already exists")
      else
        cmd = %W[git clone --branch master --single-branch --depth=200 #{EE_REPO} #{repo_dir}]
        step("Cloning #{EE_REPO} into #{repo_dir}", cmd)
      end
    end

    def ensure_patches_dir
      FileUtils.mkdir_p(patches_dir)
    end

    def generate_patch(branch, patch_path)
      FileUtils.rm(patch_path, force: true)

      fetch_deeper(branch: branch) unless merge_base_found?

      step(
        "Generating the patch against origin/master in #{patch_path}",
        %w[git format-patch origin/master --stdout]
      ) do |output, status|
        throw(:halt_check, :ko) unless status.zero?

        File.write(patch_path, output)

        throw(:halt_check, :ko) unless File.exist?(patch_path)
      end
    end

    def ce_branch_compat_check!
      if check_patch(ce_patch_full_path).zero?
        puts applies_cleanly_msg(ce_branch)
        throw(:halt_check)
      end
    end

    def ee_branch_presence_check!
      _, status = step("Fetching origin/#{ee_branch_prefix}", %W[git fetch origin #{ee_branch_prefix}])

      if status.zero?
        @ee_branch_found = ee_branch_prefix
      else
        _, status = step("Fetching origin/#{ee_branch_suffix}", %W[git fetch origin #{ee_branch_suffix}])
      end

      if status.zero?
        @ee_branch_found = ee_branch_suffix
      else
        puts
        puts ce_branch_doesnt_apply_cleanly_and_no_ee_branch_msg

        throw(:halt_check, :ko)
      end
    end

    def ee_branch_compat_check!
      step("Checking out origin/#{ee_branch_found}", %W[git checkout -b #{ee_branch_found} FETCH_HEAD])

      generate_patch(ee_branch_found, ee_patch_full_path)

      unless check_patch(ee_patch_full_path).zero?
        puts
        puts ee_branch_doesnt_apply_cleanly_msg

        throw(:halt_check, :ko)
      end

      puts
      puts applies_cleanly_msg(ee_branch)
    end

    def check_patch(patch_path)
      step("Checking out master", %w[git checkout master])
      step("Resetting to latest master", %w[git reset --hard origin/master])

      output, status = step("Checking if #{patch_path} applies cleanly to EE/master", %W[git apply --check --3way #{patch_path}])

      unless status.zero?
        @failed_files = output.lines.reduce([]) do |memo, line|
          if line.start_with?('error: patch failed:')
            file = line.sub(/\Aerror: patch failed: /, '')
            memo << file unless file =~ IGNORED_FILES_REGEX
          end
          memo
        end

        status = 0 if failed_files.empty?
      end

      status
    end

    def delete_ee_branches_locally!
      command(%w[git checkout master])
      command(%W[git branch -D #{ee_branch_prefix}])
      command(%W[git branch -D #{ee_branch_suffix}])
    end

    def merge_base_found?
      _, status = Gitlab::Popen.popen(%w[git merge-base origin/master HEAD])

      status.zero?
    end

    def fetch_deeper(branch:)
      # Start with (Math.exp(3).to_i = 20) until (Math.exp(6).to_i = 403)
      # In total we go (20 + 54 + 148 + 403 = 625) commits deeper
      depth = 20
      success =
        (3..6).any? do |factor|
          depth += Math.exp(factor).to_i
          # Repository is initially cloned with a depth of 20 so we need to fetch
          # deeper in the case the branch has more than 20 commits on top of master
          fetch(branch: branch, depth: depth)
          fetch(branch: 'master', depth: depth)

          _, status = Gitlab::Popen.popen(%w[git merge-base origin/master HEAD])

          status.zero?
        end

      raise "\n#{branch} is too far behind master, please rebase it!\n" unless success
    end

    def fetch(branch:, depth:)
      cmd = %W[git fetch --depth=#{depth} --prune origin +refs/heads/#{branch}:refs/remotes/origin/#{branch}]
      out, status = Gitlab::Popen.popen(cmd)

      raise "Fetch failed: #{out}" unless status.zero?
    end

    def ce_patch_name
      @ce_patch_name ||= patch_name_from_branch(ce_branch)
    end

    def ce_patch_full_path
      @ce_patch_full_path ||= patches_dir.join(ce_patch_name)
    end

    def ee_branch_suffix
      @ee_branch_suffix ||= "#{ce_branch}-ee"
    end

    def ee_branch_prefix
      @ee_branch_prefix ||= "ee-#{ce_branch}"
    end

    def ee_patch_name
      @ee_patch_name ||= patch_name_from_branch(ee_branch)
    end

    def ee_patch_full_path
      @ee_patch_full_path ||= patches_dir.join(ee_patch_name)
    end

    def patch_name_from_branch(branch_name)
      branch_name.parameterize << '.patch'
    end

    def step(desc, cmd = nil)
      puts "\n=> #{desc}\n"

      if cmd
        start = Time.now
        puts "\n$ #{cmd.join(' ')}"

        output, status = command(cmd)
        yield(output, status) if block_given?

        puts "\nFinished in #{Time.now - start} seconds"

        [output, status]
      end
    end

    def command(cmd)
      Gitlab::Popen.popen(cmd)
    end

    def applies_cleanly_msg(branch)
      <<-MSG.strip_heredoc
        =================================================================
        =================================================================
        =================================================================
        🎉 Congratulations!! 🎉

        The #{branch} branch applies cleanly to EE/master!

        Much ❤️!!
        =================================================================
        =================================================================
        =================================================================\n
      MSG
    end

    def ce_branch_doesnt_apply_cleanly_and_no_ee_branch_msg
      <<-MSG.strip_heredoc
        =================================================================
        =================================================================
        =================================================================
        💥 Oh no! 💥

        The #{ce_branch} branch does not apply cleanly to the current
        EE/master, and no `#{ee_branch_prefix}` or `#{ee_branch_suffix}` branch
        was found in the EE repository.

        #{conflicting_files_msg}

        We advise you to create a `#{ee_branch_prefix}` or `#{ee_branch_suffix}`
        branch that includes changes from #{ce_branch} but also specific changes
        than can be applied cleanly to EE/master. In some cases, the conflicts
        are trivial and you can ignore the warning from this job. As always,
        use your best judgment!

        Follow the following steps to create this branch:

        1. Create a new branch from master and cherry-pick your CE commits

          # In the EE repo
          $ git fetch origin
          $ git checkout -b #{ee_branch_prefix} origin/master
          $ git fetch #{ce_repo} #{ce_branch}
          $ git cherry-pick SHA # Repeat for all the commits you want to pick

        2. You can squash the #{ce_branch} commits into a single "Port of #{ce_branch} to EE" commit.

        3. Don't forget to push your branch to gitlab-ee:

          # In the EE repo
          $ git push origin #{ee_branch_prefix}

        You can then retry this failed build, and hopefully it should pass.

        Stay 💪 !
        =================================================================
        =================================================================
        =================================================================\n
      MSG
    end

    def ee_branch_doesnt_apply_cleanly_msg
      <<-MSG.strip_heredoc
        =================================================================
        =================================================================
        =================================================================
        💥 Oh no! 💥

        The #{ce_branch} does not apply cleanly to the current EE/master, and
        even though a `#{ee_branch_found}` branch
        exists in the EE repository, it does not apply cleanly either to
        EE/master!

        #{conflicting_files_msg}

        Please update the `#{ee_branch_found}`, push it again to gitlab-ee, and
        retry this build.

        Stay 💪 !
        =================================================================
        =================================================================
        =================================================================\n
      MSG
    end

    def conflicting_files_msg
      msg = "The conflicts detected were as follows:\n\n"
      failed_files.each { |file| msg << "  - #{file}\n" }
      msg << "\n"
    end
  end
end
