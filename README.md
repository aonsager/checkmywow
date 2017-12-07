## Check My Wow

This site is made for World of Warcraft players who want to improve by tracking their performance across raid encounters, based on key metrics for their spec.

It is designed primarily for those who want to improve their basic rotation. It probably will not provide enough information to be useful to advanced players who are already very comfortable with their classes and are now trying to maximize their output.

## Running the site

To run the site you need ruby >= 2.2 and rails >= 4.2

### Web server

```
gem install bundler
bundle install
bundle exec rake db:migrate
bundle exec rails s -p 3000
```

You can now see the site in your browser at `http://localhost:3000`

Visit `http://localhost:3000/zones` to get the latest list of raid zones and bosses from Warcraft Logs.

### Worker queue

Check my Wow uses a pool of Resque threads to process fights in the background. Run the following command to start the processes:

```
TERM_CHILD=1 RESQUE_TERM_TIMEOUT=10 LOGGING=1 bundle exec resque-pool -E development
```

Now you should be able to process fights normally.
Logs will be outputted to `log/resque.log`, and you can see a dashboard of the current running tasks at localhost:3000/resque

## Site organization

### Processing

`app/jobs/` contains the Resque processes that do all of the parsing. `parser.rb` grabs entire reports from WCL and `single_parser.rb` parses a single fight/player. SingleParser takes each relevant event and passes it to the spec's FightParse class, which will perform any necessary calculations.

`app/models/fight_parse.rb` holds all of the common logic for all classes when parsing fights. Things like keeping track of DPS, the number of times each spell was cast, watching for buffs, are all contained here. `app/models/healer_parse.rb` has extra functions common to healers, and `app/models/tank_parse.rb` has extra functions common to healers. Class-specific logic is in `app/models/fight_parse/{class}/{spec}` where there is a class for each unique spec in the game. 

### Database tables

`fight_parse_records` will have one record for each person in each encounter, and has basic information about the player and the encounter. Once a fight is parsed, all of the numbers will saved in `fp_{class}_{spec}`. When tracking what happens during a certain buff's uptime, there will be one `cooldown_parse` record for each instance the buff was active. For simply tracking uptimes/downtimes throughout the fight, one record per ability will be created in `buff_parses` or `debuff_parses`. 

### Views

Previously, each spec had folders in `app/views/bosses` and `app/views/fight_parses` that defined the data that is shown in the completed analysis. I started migrating to a new model where `app/models/display_section/{class}/{spec}` will contain a list of methods that can populate a page template (`app/views/show_data.html.erb`) with the correct data. I didn't finish migrating all specs, so some logic is still in `app/views/bosses` and `app/views/fight_parses`.
