import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DateTimeHelper {
  // Format timestamp for chat message
  static String formatMessageTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('h:mm a').format(dateTime);
  }
  
  // Format last seen timestamp
  static String formatLastSeen(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Last seen ${DateFormat('MMM d').format(dateTime)}';
    } else if (difference.inHours > 0) {
      return 'Last seen ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return 'Last seen ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Last seen just now';
    }
  }
  
  // Format timestamp for chat list
  static String formatChatListTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      if (difference.inDays > 6) {
        return DateFormat('MMM d').format(dateTime);
      } else {
        return DateFormat('E').format(dateTime); // Day of week
      }
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }
}
