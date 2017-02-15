module MattermostHelper
  def mattermost_teams_options(teams)
    teams.map do |props|
      [props['display_name'] || props['name'], props['id']]
    end
  end
end
