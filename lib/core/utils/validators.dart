class Validators {
  // Validate message is not empty
  static bool isValidMessage(String message) {
    return message.trim().isNotEmpty;
  }
  
  // Validate user ID
  static bool isValidUserId(String userId) {
    return userId.isNotEmpty;
  }
}