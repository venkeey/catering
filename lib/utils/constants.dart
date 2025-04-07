class Constants {
  // Database
  static const String dbHost = 'localhost';
  static const int dbPort = 3306;
  static const String dbUser = 'root';
  static const String dbPassword = 'master003';
  static const String dbName = 'catererer_db';

  // Event Status
  static const String eventStatusPlanning = 'Planning';
  static const String eventStatusConfirmed = 'Confirmed';
  static const String eventStatusCompleted = 'Completed';
  static const String eventStatusCancelled = 'Cancelled';

  // Quote Status
  static const String quoteStatusDraft = 'Draft';
  static const String quoteStatusSent = 'Sent';
  static const String quoteStatusAccepted = 'Accepted';
  static const String quoteStatusRejected = 'Rejected';
  static const String quoteStatusRevised = 'Revised';

  // Calculation Methods
  static const String calcMethodStandard = 'Standard';
  static const String calcMethodPercentageTakeRate = 'Percentage Take Rate';
  static const String calcMethodCustom = 'Custom';

  // Item Types
  static const String itemTypeStandard = 'Standard';
  static const String itemTypePercentageChoice = 'PercentageChoice';

  // Default Values
  static const double defaultOverheadPercentage = 15.0;
  static const double defaultPortionSize = 100.0; // grams
  static const double defaultBaseFoodCost = 0.0;
  static const int defaultGuestCount = 0;

  // Form Validation
  static const int maxNameLength = 200;
  static const int maxPhoneLength = 20;
  static const int maxEmailLength = 100;
  static const int maxAddressLength = 500;
  static const int maxNotesLength = 1000;
  static const int maxTermsLength = 2000;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultIconSize = 24.0;
  static const double defaultButtonHeight = 48.0;
  static const double defaultTextFieldHeight = 56.0;
  static const double defaultCardElevation = 2.0;

  // Date Formats
  static const String dateFormatDisplay = 'MMM d, y';
  static const String dateFormatInput = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'MMM d, y HH:mm';
  static const String dateTimeFormatInput = 'yyyy-MM-dd HH:mm';

  // Currency
  static const String currencySymbol = '₹';
  static const int currencyDecimalPlaces = 2;

  // Weight Units
  static const String weightUnitGrams = 'g';
  static const String weightUnitKilograms = 'kg';

  // Error Messages
  static const String errorRequired = 'This field is required';
  static const String errorInvalidEmail = 'Please enter a valid email address';
  static const String errorInvalidPhone = 'Please enter a valid phone number';
  static const String errorInvalidNumber = 'Please enter a valid number';
  static const String errorInvalidDate = 'Please enter a valid date';
  static const String errorInvalidTime = 'Please enter a valid time';
  static const String errorDatabaseConnection = 'Unable to connect to database';
  static const String errorUnknown = 'An unknown error occurred';

  // Success Messages
  static const String successSaved = 'Changes saved successfully';
  static const String successDeleted = 'Item deleted successfully';
  static const String successCreated = 'Item created successfully';
  static const String successUpdated = 'Item updated successfully';
} 