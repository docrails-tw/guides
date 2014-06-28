module RailsGuides
  module Levenshtein
    # Based on the pseudocode in http://en.wikipedia.org/wiki/Levenshtein_distance
    def self.distance(s1, s2)
      require 'amatch'
      Amatch::Levenshtein.new(s1).match s2
    end
  end
end
