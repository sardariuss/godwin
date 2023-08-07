
const CONSTANTS = {
  INTEREST_INFO: {
    down: {
      symbol: '🤡',
      color: '#DB4437',
      name: 'TROLL',
    },
    neutral: {
      symbol: '😴',
      color: '#EEEEEE',
      name: 'BORING',
    },
    up: {
      symbol: '🤓',
      color: '#4285F4',
      name: 'LEGIT',
    }
  },
  DUPLICATE: {
    symbol: '👀',
    color: '#EEEEEE',
    name: 'DUPLICATE',
  },
  OPINION_INFO: {
    left: {
      symbol: '👎',
      color: '#DB4437',
      name: 'DISAGREE',
    },
    center: {
      symbol: '🤷',
      color: '#EEEEEE',
      name: 'UNDECIDED'
    },
    right: {
      symbol: '👍',
      color: '#0F9D58',
      name: 'AGREE',
    }
  },
  CATEGORIZATION_INFO: {
    center: {
      symbol: '🎯',
      color: '#EEEEEE',
      name: 'CENTER'
    }
  },
  USER_NAME: {
    DEFAULT: 'New user'
  },
  TOKEN_DECIMALS: 2,
  CURSOR_DECIMALS: 2,
  CURSOR_SIDE_THRESHOLD: 0.1,
  DECAY_DECIMALS: 2,
  CHART: {
    BORDER_COLOR_LIGHT: '#bbbbbb',
    BORDER_COLOR_DARK: '#333333',
    BAR_CHART_BORDER_WIDTH: 1.2,
  },
  HELP_MESSAGE: {
    CATEGORIZATION_VOTE: 'Users who agree on this statement shall have their convictions updated towards...',
    DELETED_QUESTION: 'This question has been deleted.',
  },
  OPEN_QUESTION: {
    PLACEHOLDER: "What's interesting to vote on?",
    PICK_SUB: "Choose a sub-godwin",
  },
  SICK_FILTER: {
    SEPIA_PERCENT: 40,
    HUE_ROTATE_DEG: 39,
  },
  MAX_NUM_CHARACTERS_REACHED: 'Max number of characters reached',
  MAX_NUM_CATEGORIES: 8,
  NEW_SUB_DEFAULT_PARAMETERS: {
    CATEGORY: {
      EMOJI: '❔',
      COLOR: '#000000',
    },
    SELECTION_PARAMETERS: {
      selection_period:          { 'HOURS'  : BigInt(12)},
      minimum_score: 5.0,
    },
    SCHEDULER_PARAMETERS: {
      censor_timeout:            { 'HOURS'  : BigInt(4) },
      candidate_status_duration: { 'DAYS'   : BigInt(3) },
      open_status_duration:      { 'DAYS'   : BigInt(2) },
      rejected_status_duration:  { 'DAYS'   : BigInt(5) },
    },
    CONVICTIONS_PARAMETERS: {
      vote_half_life:        { 'YEARS'  : BigInt(1)  },
      late_ballot_half_life: { 'DAYS'   : BigInt(7)  },
    },
    CHARACTER_LIMIT: BigInt(500)
  }
};

export default CONSTANTS;