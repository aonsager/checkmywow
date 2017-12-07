crumb :root do
  link "Home", root_path
end

crumb :guild do |guild_id|
  guild = Guild.find(guild_id)
  link guild.name, guild_path(guild_id)
end

crumb :report do |report, reload=false|
  link "Reload from WCL", report_reload_path(report.report_id) if reload
  link report.title, report_path(report.report_id)
  parent :guild, report.guilds.first.id unless report.guilds.count == 0
end

crumb :fight_boss do |report, fight, player_id, player_name, player_class, player_spec, tab|
  bosses = {}
  fight_ids = FightParseRecord.where(report_id: report.report_id, player_id: player_id).pluck(:fight_guid)
  ActiveRecord::Base.connection.execute("select name, kill, count(1), max(fight_id) as latest from fights where id in (#{fight_ids.join(',')}) group by name, kill").each do |row|
    bosses[row['name']] ||= {'t' => 0, 'f' => 0, 'latest' => 0}
    bosses[row['name']][row['kill']] = row['count'].to_i
    if row['kill'] == 't' || bosses[row['name']]['latest'] == 0
      bosses[row['name']]['latest'] = row['latest'].to_i
    end
  end
  bosses = bosses.to_a.sort{|a, b| a[1]['latest'] <=> b[1]['latest']}
  link render 'breadcrumbs/fight_bosses_dropdown', report: report, fight: fight, bosses: bosses, player_id: player_id, tab: tab
  # parent :fight_player, report, fight, player_id, player_name, player_class, player_spec
  parent :report, report
end

crumb :fight_parse do |report, fight, player_id, player_name, player_class, player_spec, tab|
  link render 'breadcrumbs/fights_dropdown', report: report, fight: fight, player_id: player_id, tab: tab
  parent :fight_boss, report, fight, player_id, player_name, player_class, player_spec, tab
end

crumb :fight_player do |report, fight, player_id, player_name, player_class, player_spec, tab|
  players = FightParseRecord.select('player_id', 'player_name', 'class_type').where(report_id: report.report_id, fight_id: fight.fight_id).group(:player_id, :player_name, :class_type, :spec).order(:class_type).pluck(:player_id, :player_name, :class_type, :spec)
  link render 'breadcrumbs/players_dropdown', report: report, fight_id: fight.fight_id, player_name: player_name, player_class: player_class, player_spec: player_spec, players: players
  parent :fight_parse, report, fight, player_id, player_name, player_class, player_spec, tab
  # parent :report, report
end

crumb :player do |player_id, player_name|
  link player_name, player_path(player_id)
end

crumb :boss do |boss_id, boss_name, difficulty, player_id, player_name|
  link "#{boss_name} (#{DifficultyType.label(difficulty)})", player_boss_show_path(player_id, boss_id, difficulty)
  parent :player, player_id, player_name
end

# crumb :projects do
#   link "Projects", projects_path
# end

# crumb :project do |project|
#   link project.name, project_path(project)
#   parent :projects
# end

# crumb :project_issues do |project|
#   link "Issues", project_issues_path(project)
#   parent :project, project
# end

# crumb :issue do |issue|
#   link issue.title, issue_path(issue)
#   parent :project_issues, issue.project
# end

# If you want to split your breadcrumbs configuration over multiple files, you
# can create a folder named `config/breadcrumbs` and put your configuration
# files there. All *.rb files (e.g. `frontend.rb` or `products.rb`) in that
# folder are loaded and reloaded automatically when you change them, just like
# this file (`config/breadcrumbs.rb`).