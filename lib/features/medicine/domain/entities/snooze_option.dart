enum SnoozeOption {
  fiveMinutes(5),
  tenMinutes(10),
  fifteenMinutes(15),
  thirtyMinutes(30);

  final int minutes;

  const SnoozeOption(this.minutes);
}

//Isse invalid snooze like 17 minutes accidentally business layer tak nahi jayega.
