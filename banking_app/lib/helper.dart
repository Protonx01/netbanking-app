
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


String DB_Path = "";
int currentAccNo = 0;


Future<void> getPermission(Permission permission) async {
  print(await permission.status);
  if (await permission.status.isGranted) {
    return;
  } else if (await permission.status.isPermanentlyDenied) {
  } else {
    await permission.request();
  }
}

Future<void> initDatabase() async {
  await _getPath();
  print(DB_Path);
  final db = await _getDatabase(DB_Path);
  await db.close();
  print(_alert("Database Creation Done"));

}


Future<List<Widget>> getCustomerWidgetList(BuildContext context) async {

  Widget _custDetails (String cName, cNo) {
    return GestureDetector(
      onTap: (){
        currentAccNo = cNo;
        Navigator.of(context).pushNamed('/details');

        print(_alert("tapped on ${cName}"));
      },
      child: Container(
        margin: EdgeInsets.all(10),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          children: [
            SizedBox(height: 4.0,),
            Text(
              cName,
              style: TextStyle(

                  fontSize: 25
              ),
            ),
            SizedBox(height: 3.0),
            Text(
              "Account no: ${cNo}",
              style: TextStyle(
                fontSize: 20
              ),
            ),
            SizedBox(height: 4.0,)
          ],
        ),
      ),
    );
  }


  List<Widget> _widgets = [];

  var data = await _getAllData();

  for (int i = 0; i < data.length; i++) {
    var name = data.elementAt(i)["name"];
    var acc_no = data.elementAt(i)["acc_no"];
    _widgets.add(_custDetails(name, acc_no));
  }

  return _widgets;
}

Future<List<Widget>> getTransactionWidgetList() async {

  Widget _transactionDetails(int tNo, tFrom, tTo, int tAmount, String tdate) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(30)
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                "$tNo",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 50
                ),

              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("From"),
                    Text(
                      "$tFrom",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 10.0,),
                    Text("To"),
                    Text(
                      "$tTo",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    )
                  ],
                ),
              ),

              Text(
                "$tAmount",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25
                ),

              ),

            ],
          ),
          SizedBox(height: 20.0,),
          Text(
            tdate,
            style: TextStyle(fontWeight: FontWeight.w400,),
          )
        ],
      ),
    );
  }

  List<Widget> _widgets = [];

  var data = await getTransactions();

  for (int i = 0; i < data.length; i++) {
    var num = data.elementAt(i)["trans_id"];
    var tName = data.elementAt(i)["tname"];
    var fName = data.elementAt(i)["fname"];
    var amount = data.elementAt(i)["amount"];
    var date = data.elementAt(i)["t_date"].toString();

    _widgets.add(_transactionDetails(num, fName, tName, amount, date));
  }

  return _widgets;
}

Future<List> _getAllData() async {
  final db = await _getDatabase(DB_Path);
  var s = await db.rawQuery("select name, acc_no, balance from accounts");

  print(_alert("grabbed data successfully"));

  return s;
}

Future<List> getAllData2(int accno) async {
  final db = await _getDatabase(DB_Path);
  var query = "SELECT name, acc_no from accounts where acc_no != ${accno}";
  var s = await db.rawQuery(query);

  return s;
}

Future<List> getCustData(int accno) async {

  final db = await _getDatabase(DB_Path);
  final query = "select * from accounts where acc_no = ${accno}";
  var s = await db.rawQuery(query);

  print(_alert("grabbed data successfully"));

  return s;
}

Future transferAmount(int _toAcc, int _fromAcc, int amount) async {
  final db = await _getDatabase(DB_Path);

  var s = await db.rawQuery("SELECT last_trans from transaction_no");
  var n = s.elementAt(0)["last_trans"];

  var q1 = "UPDATE accounts SET balance = balance - $amount WHERE acc_no = $_fromAcc";
  var q2 = "UPDATE accounts SET balance = balance + $amount WHERE acc_no = $_toAcc";
  var q3 = "INSERT into transactions VALUES($n , $amount, $_toAcc, $_fromAcc, CURRENT_TIMESTAMP)";
  var q4 = "DELETE from transaction_no WHERE last_trans = $n";
  var q5 = "INSERT into transaction_no VALUES(${(n as int)+1})";

  Batch bt = db.batch();
  bt.execute(q1);
  bt.execute(q2);
  bt.execute(q3);
  bt.execute(q4);
  bt.execute(q5);
  await bt.commit(noResult: true);

}

Future<List> getTransactions() async {
  final db = await _getDatabase(DB_Path);
  var s = await db.rawQuery("""
        select a.trans_id, c.name as fname,  b.name as tname, a.amount, a.t_date from
        transactions as a
        JOIN accounts as b on b.acc_no =  a.to_accno
        JOIN accounts as c on c.acc_no = a.from_accno
        order by a.trans_id desc
        """);

  return s;
}

Future<List> getcustTransactions(int accNo) async {
  //todo finish this
  final db = await _getDatabase(DB_Path);
  var query = """
              select a.name as fname, b.name as tname, c.amount from
              transactions as d
              JOIN accounts as a on a.acc_no = d.from_accno
              JOIN accounts as b on b.acc_no = $accNo 
              """;
  var s = db.rawQuery(query);
  return s;
}

Future<List> testSql() async {
  final db = await _getDatabase(DB_Path);
  var s = await db.rawQuery("select CURRENT_TIMESTAMP");
  db.close();

  return s;
}


Future _alterTableTest() async {
  final db = await _getDatabase(DB_Path);
  await db.execute("ALTER TABLE accounts DROP phno;");
  await db.close();
  print(_alert("altered table"));
}

Future _getPath() async {
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path,  "AppDB.db");
  DB_Path = path;

}

Future<Database> _getDatabase(String path) async {
  File file = File(path);
  if (!await file.exists()){
    file = await File(path).create(recursive: true);
    return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        singleInstance: false
    );
  }else {
    return await openDatabase(
        path,
        version: 1,
        singleInstance: false
    );
  }
}

Future _onCreate(Database db, int version) async {

  print(_alert("Table creation started"));
  Batch bt = db.batch();
  bt.execute('''
        CREATE TABLE accounts (
        acc_no LONG primary key,
        name varchar(50),
        balance LONG,
        email varchar(50)
        );
        ''');

  bt.execute('''
        CREATE TABLE transactions (
        trans_id LONG primary key,
        amount LONG,
        to_accno LONG,
        from_accno LONG,
        t_date DATE
        );
        ''');

  bt.execute("""
        CREATE TABLE transaction_no (
        last_trans LONG primary key  
        );
  """);

  print(_alert("data entry started"));
  //enter values
  bt.execute("INSERT INTO accounts VALUES (1905667987891001, 'Harihar Jha', 200000, 'hariharjha334@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891002, 'Dipankar Bose', 180000, 'dipankar56@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891003, 'Tulika Ray', 500000, 'ctulikaray@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891004, 'Rumi Ghose', 9000, 'rumirumi9090@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891005, 'Nilam Roy', 11000, 'nilamroy009@yahoo.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891006, 'Manowar Iqbal', 1600000, 'manowariqbal@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891007, 'Aritra Chaterjee', 18000, 'aritrachaterjee@hotmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891008, 'Kapil Deb', 12900000, 'captainkapil@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891009, 'Somyajit Sinha', 300, 'soumyajityoyo@gmail.com')");
  bt.execute("INSERT INTO accounts VALUES (1905667987891010, 'Trikaleshwar Nandi', 40000, 'triloknandi78@gmail.com')");
  bt.execute("INSERT INTO transaction_no VALUES (1)");

  await bt.commit(noResult: true);

  print(_alert("Data entry done"));
}


Future dropDatabase() async {
  var dir = File(DB_Path);
  DB_Path = "";
  await dir.delete();
  print(_alert("Database Deleted Successfully"));
}

String _alert(String s) {
  return "\n!!!\n\n${s}\n\n!!!\n";
}















