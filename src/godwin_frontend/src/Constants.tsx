
const CONSTANTS = {
  INTEREST_INFO: {
    down: {
      symbol: '👹',
      color: '#DB4437',
      name: 'CENSOR',
    },
    neutral: {
      symbol: '😴',
      color: '#EEEEEE',
      name: 'BORING',
    },
    up: {
      symbol: '🧐',
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
  USER: {
    DEFAULT_NAME: 'New user',
    DEFAULT_AVATAR: '😀'
  },
  TOKEN_DECIMALS: 0,
  CURSOR_DECIMALS: 2,
  CURSOR_SIDE_THRESHOLD: 0.1,
  DECAY_DECIMALS: 2,
  CHART: {
    BORDER_COLOR_LIGHT: '#bbbbbb',
    BORDER_COLOR_DARK: '#333333',
    BAR_CHART_BORDER_WIDTH: 1.2,
  },
  INSTRUCTION_BULLET: "🪒",
  INFO_BULLET: "💈",
  HELP_MESSAGE: {
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
  QUESTION_MARK_NOT_ALLOWED: 'Question mark is not allowed',
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
  },
  SUB_DOES_NOT_EXIST: "Sorry, there isn't any sub with that name.",
  USER_DOES_NOT_EXIST: "Sorry, there isn't any user with that principal.",
  EMPTY_HOME: "You're done! Come back later or browse the results 🔎",
  GENERIC_EMPTY: "It's quite empty here 💤",
};

export default CONSTANTS;