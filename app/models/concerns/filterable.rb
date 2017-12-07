module Filterable
  extend ActiveSupport::Concern

  included do
    filterrific(
      default_filter_params: { 
        sorted_by: 'casts_score_desc',
        kill: true,
      },
      available_filters: [
        :kill,
        :boss,
        :sorted_by,
        :talents,
        :fight_length,
        :difficulty,
      ]
    )

    scope :boss, lambda {|boss_id|
      return nil if boss_id.nil?
      where("boss_id = ?", boss_id)
    }
    
    scope :kill, lambda {|kill|
      where("kill = true")
    }
    scope :talents, lambda { |talents|
      return nil  if talents.blank?
      where("talents = ? ", talents)
    }

    scope :fight_length, lambda { |length_attrs|
      return nil if length_attrs.blank? || length_attrs[:range].to_i == 0
      where('fight_length between ? and ?', length_attrs[:length].to_i - length_attrs[:range].to_i, length_attrs[:length].to_i + length_attrs[:range].to_i)
    }

    scope :difficulty, lambda { |difficulty|
      where('difficulty = ?', difficulty.to_i)
    }

    scope :sorted_by, lambda { |sort_option|
      direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'
      case sort_option.to_s
      when /^casts_score/
        order("casts_score #{ direction } nulls last")
      when /^cooldowns_score/
        order("cooldowns_score #{ direction } nulls last")
      when /^voidform_uptime/
        order("voidform_uptime #{ direction } nulls last")
      else
        raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
      end
    }
  end

  def self.percent_label(mine, theirs)
    return "N/A" if mine == 0 || theirs == 0
    percent = theirs - mine
    color = percent > 15 ? 'green' : percent < -15 ? 'red' : ''
    return "<span class='#{color}'>#{percent}% #{mine == theirs ? '' : theirs > mine ? '↑' : '↓'}</span>"
  end
end