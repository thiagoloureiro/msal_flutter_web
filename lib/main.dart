import 'package:flutter/material.dart';
import 'package:msal_js/msal_js.dart';

// **Setup your directory settings here:**
const String clientId = '1de336bc-c4bc-489a-8f9f-6c31d7d0fd58';
const List<String> scopes = [];

void main() {
  // Create an MSAL logger
  final logger = Logger(
    _loggerCallback,
    LoggerOptions()
      // Log everything for the purpose of this demo
      ..level = LogLevel.verbose,
  );

  // Create an MSAL UserAgentApplication
  final userAgentApplication = UserAgentApplication(
    Configuration()
      ..auth = (AuthOptions()..clientId = clientId)
      ..system = (SystemOptions()..logger = logger),
  );

  // Setup a callback for the redirect login flow
  //
  // **IMPORTANT NOTE:** It is highly recommended to setup
  // your UserAgentApplication and call handleRedirectCallback
  // sometime before your Flutter app starts. The router in
  // the [MaterialApp] widget will clear the URL when it loads
  // which will prevent MSAL from getting the token from it
  // after a redirect login.
  userAgentApplication.handleRedirectCallback(_redirectCallback);

  // Start the Flutter app
  runApp(MyApp(userAgentApplication: userAgentApplication));
}

void _loggerCallback(LogLevel level, String message, bool containsPii) {
  // MSAL log message
  print('MSAL: [$level] $message');
}

void _redirectCallback(AuthException error, [AuthResponse response]) {
  if (error != null) {
    // Redirect login failed
    print('MSAL: ${error.errorCode}:${error.errorMessage}');
  } else {
    // Redirect login succeeded
    print('Redirect login successful. name: ${response.account.name}');
  }
}

/// Simple default Flutter app.
///
/// Passes the [UserAgentApplication] onto the home page.
class MyApp extends StatelessWidget {
  final UserAgentApplication userAgentApplication;

  MyApp({this.userAgentApplication});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web MSAL.js Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(userAgentApplication: userAgentApplication),
    );
  }
}

/// The demo home page for interacting with the
/// MSAL [UserAgentApplication].
class MyHomePage extends StatefulWidget {
  final UserAgentApplication userAgentApplication;

  MyHomePage({
    this.userAgentApplication,
    Key key,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Account _account;

  @override
  void initState() {
    super.initState();

    // Get the currently authenticated account, if any.
    //
    // After a redirect login, this returns the logged in account.
    _account = widget.userAgentApplication.getAccount();
  }

  /// Starts a redirect login.
  void _loginRedirect() {
    widget.userAgentApplication.loginRedirect(AuthRequest()..scopes = scopes);
  }

  /// Starts a popup login.
  Future<void> _loginPopup() async {
    try {
      final response = await widget.userAgentApplication
          .loginPopup(AuthRequest()..scopes = scopes);

      setState(() {
        _account = response.account;
      });

      print('Popup login successful. name: ${_account.name}');
    } on AuthException catch (ex) {
      print('MSAL: ${ex.errorCode}:${ex.errorMessage}');
    }
  }

  /// Logs the current account out.
  void _logout() {
    widget.userAgentApplication.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Web MSAL.js Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_account == null) ...[
              ElevatedButton(
                child: Text('Login Redirect'),
                onPressed: _loginRedirect,
              ),
              ElevatedButton(
                child: Text('Login Popup'),
                onPressed: _loginPopup,
              ),
            ],
            if (_account != null) ...[
              Text('Signed in as ${_account.name}'),
              ElevatedButton(
                child: Text('Logout'),
                onPressed: _logout,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
