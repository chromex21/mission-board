// Utility helper functions for the Mission Board app

String formatReward(int reward) {
  return '\$$reward';
}

String getDifficultyLabel(int difficulty) {
  switch (difficulty) {
    case 1:
      return 'Easy';
    case 2:
      return 'Medium';
    case 3:
      return 'Hard';
    case 4:
      return 'Very Hard';
    case 5:
      return 'Extreme';
    default:
      return 'Unknown';
  }
}
