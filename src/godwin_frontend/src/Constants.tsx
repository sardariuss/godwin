
const CONSTANTS = {
  CURSOR_DECIMALS: 2,
  CURSOR_SIDE_THRESHOLD: 0.1,
  INTEREST_INFO: {
    up: {
      symbol: '🤓',
      color: '#0F9D58',
      name: 'UP',
    },
    down: {
      symbol: '🤡',
      color: '#DB4437',
      name: 'DOWN',
    },
    duplicate: {
      symbol: '👀',
      color: '#FFFFFF',
      name: 'DUPLICATE',
    }
  },
  OPINION_INFO: {
    left: {
      symbol: '👎',
      color: '#DB4437',
      name: 'DISAGREE',
    },
    center: {
      symbol: '🤷',
      color: '#FFFFFF',
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
      color: '#FFFFFF',
      name: 'N/A'
    }
  }
};

export default CONSTANTS;