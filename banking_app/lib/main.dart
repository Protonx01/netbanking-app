import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'helper.dart' as hp;

void main() {
  runApp(Home());
}



class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/': (context) => HomePage(),
        '/alldetails': (context) => AllCustomerPage(),
        '/details': (context) => CustomerDetails(),
        '/transfer': (context) => TransferPage(),
        '/transdetails' :(context) => TransactionDetailsPage()
      },
    );
  }
}



class HomePage extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {}
          ),
          backgroundColor: Colors.grey,
          centerTitle: true,
          title: Text(
            "Banking App",
            style: TextStyle(fontSize: 25, color: Colors.yellow),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.extended(
                heroTag: "allcustomer",
                onPressed: () {
                  Navigator.pushNamed(context, "/alldetails");
                },
                label: Text(
                  "View All Customer",
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                backgroundColor: Colors.yellow[600],
                elevation: 0.0,

              ),
              SizedBox(
                height: 20,
              ),
              FloatingActionButton.extended(
                heroTag: "alltransaction",
                onPressed: () {
                  Navigator.pushNamed(context, "/transdetails");
                },
                label: Text(
                  "View All Transaction",
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
                elevation: 0.0,
                backgroundColor: Colors.yellow[600],
              ),
              SizedBox(height: 100.0,)
            ],
          ),
        ));
  }
}



class AllCustomerPage extends StatefulWidget {
  @override
  _AllCustomerPageState createState() => _AllCustomerPageState();
}
class _AllCustomerPageState extends State<AllCustomerPage> {
  List<Widget> widgetList = [];

  @override
  void initState() {
    super.initState();
    asyncCalls();
  }

  void asyncCalls() async {
    // await hp.dropDatabase();
    await hp.initDatabase();
    final _widgets = await hp.getCustomerWidgetList(this.context);
    // await Future.delayed(Duration(seconds: 2));
    setState(() {
      widgetList = _widgets;
      widgetList.add(SizedBox(height: 50.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        Navigator.pushNamed(context, "/");
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey,
            centerTitle: true,
            title: Text(
              "Customer Details",
              style: TextStyle(color: Colors.yellow),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: widgetList,
            ),
          )
      ),
    );
  }
}



class CustomerDetails extends StatefulWidget {
  @override
  _CustomerDetailsState createState() => _CustomerDetailsState();
}
class _CustomerDetailsState extends State<CustomerDetails> {
  String _name = "";
  var _accno = 0;
  var _balance = 0;
  String _email = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      _accno = hp.currentAccNo;
    });
    asyncCalls();
  }

  void asyncCalls() async {
    var data = await hp.getCustData(_accno);
    setState(() {
      _name = data.elementAt(0)["name"].toString();
      _balance = data.elementAt(0)["balance"];
      // print(_balance.runtimeType);
      _email = data.elementAt(0)["email"].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$_name details", style: TextStyle(color: Colors.yellow)),
        centerTitle: true,
        backgroundColor: Colors.grey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            SizedBox(height: 20.0),

            Text("Name::"),
            SizedBox(height: 5.0),
            Text(_name, style: TextStyle(fontSize: 30)),

            SizedBox(height: 20.0),

            Text("Account No::"),
            SizedBox(height: 5.0),
            Text(_accno.toString(), style: TextStyle(fontSize: 30)),

            SizedBox(height: 20.0),

            Text("Current Balance::"),
            SizedBox(height: 5.0),
            Text(_balance.toString(), style: TextStyle(fontSize: 30)),

            SizedBox(height: 20.0),

            Text("E-mail::"),
            SizedBox(height: 5.0),
            Text(_email.toString(), style: TextStyle(fontSize: 20)),

            SizedBox(height: 60.0),

            //button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/transfer');
                // print("I am touched");
              },
              child: Container(
                height: 60.0,
                width: 300.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.yellow[800],
                ),
                child: Center(
                  child: Text(
                    "Transfer Money",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.0),

            Container(
              padding: EdgeInsets.fromLTRB(50, 10, 50, 0),
              color: Colors.grey[400],
              height: 100,
            )
          ],
        ),
      ),
    );
  }
}



class TransferPage extends StatefulWidget {
  @override
  _TransferPageState createState() => _TransferPageState();
}
class _TransferPageState extends State<TransferPage> {

  String _name = "";
  var _accno = 0;
  var _balance = 0;
  String _email = "";
  List<Widget> widgetList = [];
  int toAccno = 0;
  String toName = "";
  int amount = 0;
  bool transfer_ok = false;

  getSnackBar (String text) => SnackBar(content: Text(text));


  Widget _PopupDialog(BuildContext context, String from_name, String to_name) {

    return new AlertDialog(
      title: const Text(
        "Transaction completed successfully",
      ),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "$from_name -> $to_name",
          ),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.pushNamed(context, "/alldetails");
          },

          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<List<Widget>> GetWidgetList() async {

    Widget createCards(cName, cAccno) {
      return GestureDetector(
        onTap: () {
          setState(() {
            toAccno = cAccno;
            toName = cName;
          });
        },
        child: Card(
          elevation: 1.0,
          color: Colors.blueGrey[200],
          margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 5.0),
                child: Text(
                  cName,
                  style: TextStyle(
                    fontSize: 25.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> _widgets = [];

    var data = await hp.getAllData2(_accno);

    for(int i = 0; i < data.length; i++)
      {
        var name = data.elementAt(i)["name"];
        var acc_no = data.elementAt(i)["acc_no"];
        _widgets.add(createCards(name, acc_no));
      }
    return _widgets;

  }


  void initState() {
    super.initState();
    setState(() {
      _accno = hp.currentAccNo;
    });
    asyncCalls();
  }

  void asyncCalls() async {
    var data = await hp.getCustData(_accno);
    var _widgets = await GetWidgetList();
    setState(() {
      _name = data.elementAt(0)["name"].toString();
      _balance = data.elementAt(0)["balance"];
      // print(_balance.runtimeType);
      _email = data.elementAt(0)["email"].toString();

      widgetList = _widgets;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Transfer Money", style: TextStyle(color: Colors.yellow)),
        centerTitle: true,
        backgroundColor: Colors.grey,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Text(
                  "Balance: ${_balance}",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,

                  ),
                ),
              ),

              SizedBox(height: 10.0,),

              Text(
                "Transfer To...",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),

              SizedBox(height: 10,),

              //list of customers
              Container(
                height: 350,
                margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 40.0),
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  color: Colors.grey[200]
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: widgetList,
                  ),
                ),
              ),

              SizedBox(height: 10,),

              //amount
              Center(
                child: Container(
                  color: Colors.grey[300],
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  child: Column(
                    children: [
                      Text( "Amount",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,

                        ),
                      ),
                      Text( transfer_ok?amount.toString():0.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10,),

              //namefield
              Container(
                // height: 100,
                color: Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text( "From...",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 20.0,

                          ),
                        ),
                        Text( _name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_right_alt_outlined),
                    Column(
                      children: [
                        Text( "...To",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        Text( toName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,

                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30,),

              //textfield
              Container(
                height: 60,
                // width: 900,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  // direction: Axis.horizontal,
                  children: [
                    Container(
                        margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                        width: 250,

                        child: TextField(
                          maxLength: 7,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],

                          decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                                borderSide: new BorderSide(
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(60.0))
                            ),

                            labelText: "Enter Amount",
                            enabledBorder: OutlineInputBorder(
                                borderSide: new BorderSide(
                                  width: 2.0,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(60.0))
                              ),
                            ),
                          onChanged: (String text) {
                            print("The text now : $text");
                            setState(() {
                              amount = (text == "")?0:int.parse(text);
                              transfer_ok = false;
                            });
                          }
                        ),
                      ),

                    Container(
                      width: 60,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                        color: Colors.yellow[400],
                        border: Border.all(
                          color: Colors.black,
                          width: 3.0,
                        ),
                      ),
                      child: FlatButton(
                        onPressed: (){
                          FocusManager.instance.primaryFocus?.unfocus();

                          if (amount <= 0){
                            print("amount is invalid");
                            ScaffoldMessenger.of(context).showSnackBar(getSnackBar("Please enter a valid amount"));
                            setState(() {
                              transfer_ok = false;
                            });
                          }
                          else if (amount > _balance){
                            ScaffoldMessenger.of(context).showSnackBar(getSnackBar("Transfer amount is higher than available balance ${_balance}"));
                            setState(() {
                              transfer_ok = false;
                            });
                          }
                          else if (toName == "" || toAccno == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(getSnackBar("Please Select someone to send money to"));
                            setState(() {
                              transfer_ok = false;
                            });
                          }
                          else{
                            setState(() {
                              transfer_ok = true;
                            });
                          }
                        },

                        child: Text("OK"),
                      ),
                    ),
                  ],
                ),
              ),


              SizedBox(height: 30.0,),

              //transfer button
              Center(
                child: FloatingActionButton.extended(

                  onPressed: () async {
                    if (transfer_ok) {
                        await hp.transferAmount(toAccno, _accno, amount);
                        await showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              _PopupDialog(context, _name, toName)
                        );
                    }
                    else {
                      ScaffoldMessenger.of(context).showSnackBar(getSnackBar("Please Enter Valid credentials"));
                    }
                  },

                  elevation: 1.0,
                  backgroundColor: Colors.yellow[800],
                    icon: Icon(Icons.flash_on_rounded),
                    label: Text(
                      "Send Money",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                ),
              ),


              SizedBox(height: 40,)
            ],
          ),
        ),
      ),
    );
  }
}




class TransactionDetailsPage extends StatefulWidget {
  const TransactionDetailsPage({Key? key}) : super(key: key);

  @override
  _TransactionDetailsPageState createState() => _TransactionDetailsPageState();
}
class _TransactionDetailsPageState extends State<TransactionDetailsPage> {

  List<Widget> widgetList = [];

  @override
  void initState() {
    super.initState();
    asyncCalls();
  }

  void asyncCalls() async {
    // await hp.dropDatabase();
    // var s = await hp.getTransactions();
    // var s = await hp.testSql();
    final _widgets = await hp.getTransactionWidgetList();
    setState(() {
      widgetList = _widgets;
      widgetList.add(SizedBox(height: 50.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: Text(
          "Transactions",
          style: TextStyle(color: Colors.yellow),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: widgetList,
        ),
      )
    );
  }
}

