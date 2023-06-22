
const CONSTANTS = {
  CURSOR_DECIMALS: 2,
  CURSOR_SIDE_THRESHOLD: 0.1,
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
      name: 'N/A'
    }
  },
  USER_NAME: {
    DEFAULT: 'New user',
    MAX_LENGTH: 32,
  },
  TOKEN_DECIMALS: 2,
  CHART: {
    BORDER_COLOR_LIGHT: '#bbbbbb',
    BORDER_COLOR_DARK: '#333333',
    BAR_CHART_BORDER_WIDTH: 1.2,
  },
  HELP_MESSAGE: {
    CATEGORIZATION_VOTE: 'Users who agree on this statement shall have their convictions updated towards...',
    DELETED_QUESTION: 'This question has been deleted.',
  }
};

export default CONSTANTS;