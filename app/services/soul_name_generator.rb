class SoulNameGenerator
  # Name pools inspired by diverse cultures and fantasy
  FIRST_NAMES = {
    masculine: %w[
      Aldric Bren Castor Darius Ezra Felix Gareth Hugo Ivan Jasper
      Kael Lucian Magnus Nero Orion Perseus Quinn Rowan Silas Theron
      Ulric Victor Wyatt Xander Yorick Zephyr Akira Bjorn Cormac Dante
    ],
    feminine: %w[
      Aria Brynn Celeste Diana Elara Freya Gwen Helena Iris Juno
      Kira Luna Maya Nova Ophelia Piper Quinn Raven Sage Thea
      Uma Vera Willow Xena Yara Zara Astrid Blythe Cleo Daphne
    ],
    neutral: %w[
      Alex Bailey Casey Drew Ellis Finley Gray Haven Indigo Jesse
      Kai Lake Morgan North Ocean Phoenix River Sky Storm Vale
      Winter Ash Echo Frost Jade Onyx Rune Spark Tide Wren
    ]
  }
  
  MIDDLE_NAMES = %w[
    Ash Blaze Cloud Dawn Ember Flame Grove Hart Ice Jay
    Key Lake Moon Night Oak Pine Rain Rose Snow Star
    Stone Storm Sun Thorn Vale Wave Wind Wolf Wood Wren
  ]
  
  LAST_NAME_PREFIXES = %w[
    Black Bright Cold Dark Deep Fair Fire Frost Gold Gray
    Green High Iron Light Long Moon Night Red Silver Snow
    Star Storm Strong Swift True White Wild Wind Wise Young
  ]
  
  LAST_NAME_SUFFIXES = %w[
    blade born brook claw crest fall field fire foot forge
    frost guard hammer hand heart horn lance leaf moon shadow
    shield song spear star stone storm sworn thorn walker wind
  ]
  
  TITLES = [
    "the Brave", "the Wise", "the Swift", "the Bold", "the Keen",
    "the Stalwart", "the Cunning", "the Patient", "the Fierce", "the Noble",
    "the Persistent", "the Curious", "the Creative", "the Dauntless", "the Serene"
  ]
  
  APPEARANCE_TRAITS = {
    build: ["lithe", "sturdy", "compact", "tall", "muscular", "lean", "athletic"],
    presence: ["commanding", "gentle", "intense", "calm", "vibrant", "mysterious", "approachable"],
    movement: ["graceful", "deliberate", "quick", "fluid", "steady", "energetic", "measured"],
    aura: ["warm", "cool", "electric", "grounded", "ethereal", "solid", "dynamic"]
  }
  
  VOICE_TRAITS = {
    tone: ["melodic", "gravelly", "smooth", "resonant", "clear", "rich", "gentle"],
    cadence: ["measured", "quick", "rhythmic", "deliberate", "flowing", "staccato", "varied"],
    volume: ["soft", "moderate", "strong", "variable", "consistent", "projecting"],
    quality: ["warm", "cool", "inviting", "authoritative", "soothing", "energetic", "thoughtful"]
  }
  
  def self.generate_for_soul(soul)
    new(soul).generate
  end
  
  def initialize(soul)
    @soul = soul
    @genome = soul.genome
    @rng = Random.new(soul.soul_id.hash)
  end
  
  def generate
    {
      first_name: generate_first_name,
      middle_name: generate_middle_name,
      last_name: generate_last_name,
      portrait_seed: generate_portrait_seed,
      appearance_traits: generate_appearance_traits,
      voice_characteristics: generate_voice_characteristics
    }
  end
  
  private
  
  def generate_first_name
    # Use social_orientation to influence name type
    social = @genome["gene_7"] || 0.5
    
    if social < 0.3
      # More neutral names for less social souls
      FIRST_NAMES[:neutral].sample(random: @rng)
    elsif social > 0.7
      # Gendered names for highly social souls
      if @rng.rand < 0.5
        FIRST_NAMES[:masculine].sample(random: @rng)
      else
        FIRST_NAMES[:feminine].sample(random: @rng)
      end
    else
      # Mix of all types
      all_names = FIRST_NAMES.values.flatten
      all_names.sample(random: @rng)
    end
  end
  
  def generate_middle_name
    MIDDLE_NAMES.sample(random: @rng)
  end
  
  def generate_last_name
    prefix = LAST_NAME_PREFIXES.sample(random: @rng)
    suffix = LAST_NAME_SUFFIXES.sample(random: @rng)
    "#{prefix}#{suffix}"
  end
  
  def generate_portrait_seed
    # Consistent seed for portrait generation
    "soul_#{@soul.soul_id}_#{@soul.generation}"
  end
  
  def generate_appearance_traits
    {
      build: select_trait_by_genome(APPEARANCE_TRAITS[:build], @genome["gene_0"]),
      presence: select_trait_by_genome(APPEARANCE_TRAITS[:presence], @genome["gene_1"]),
      movement: select_trait_by_genome(APPEARANCE_TRAITS[:movement], @genome["gene_6"]),
      aura: select_trait_by_genome(APPEARANCE_TRAITS[:aura], @genome["gene_3"])
    }
  end
  
  def generate_voice_characteristics
    {
      tone: select_trait_by_genome(VOICE_TRAITS[:tone], @genome["gene_4"]),
      cadence: select_trait_by_genome(VOICE_TRAITS[:cadence], @genome["gene_5"]),
      volume: select_trait_by_genome(VOICE_TRAITS[:volume], @genome["gene_0"]),
      quality: select_trait_by_genome(VOICE_TRAITS[:quality], @genome["gene_2"])
    }
  end
  
  def select_trait_by_genome(traits, gene_value)
    # Use genome value to select trait
    index = (gene_value.abs * traits.length).floor.clamp(0, traits.length - 1)
    traits[index]
  end
end