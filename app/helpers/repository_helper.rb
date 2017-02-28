module RepositoryHelper
  def access_levels_options
    {
      push_access_levels: {
        "Roles" => ProtectedBranch::PushAccessLevel.human_access_levels.map do |id, text| 
          { id: id, text: text, before_divider: true } 
        end
      },
      merge_access_levels: {
        "Roles" => ProtectedBranch::MergeAccessLevel.human_access_levels.map do |id, text| 
          { id: id, text: text, before_divider: true } 
        end
      }
    }
  end

  def load_gon_index
    open_branches = @project.open_branches.map { |br| { text: br.name, id: br.name, title: br.name } }
    params = { open_branches: open_branches }
    gon.push(params.merge(access_levels_options))
  end
end
