
abstract interface class Recur {

  /*
  Method should return a datetime object for the next occurence from
  time provided
  */
  DateTime? getNextOccurence(DateTime time);
}