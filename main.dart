import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

typedef cb = Future<void> Function(String tableName, List<dynamic> pars);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Управление БД'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  late Connection conn;
  String? selectedTable;
  List<List<dynamic>>? _tableData;

  @override
  void initState() {
    super.initState();
    _connectToSQL();
  }

  Future<void> _connectToSQL() async {
    conn = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'dormitory',
        username: 'flutterist',
        password: 'Opti',
        
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
    print('Connected to PostgreSQL database}');
  }

  @override
  void dispose() {
    conn.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                Theme.of(context).colorScheme.primary.withOpacity(0.4),
              ],
            ),
          ),
        ),
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            Container(
              width: 500,
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  ],
                  
                )
              ),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showTableSelectionDialog(context);
                    },
                    child: const Text('Вывести таблицу'),
                  ),
                  ElevatedButton(
                    onPressed: () {   
                      _showInsertingDialog(context);
                      //_addData('student', [3,'Борис','Троянов','мужчина',18]);
                    },
                    child: const Text('Добавить данные в таблицу'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20,),
            if (selectedTable != null) ...[
              const SizedBox(height: 20),
              Text('Выбрана таблица: $selectedTable'),
              TableWidget(tableData: _tableData)
            ]

          ],
        ),
      ),
    );
  }
  Future<void> _addData(String tableName,List<dynamic> pars)async{
    try{
      final List<String> placeholders = List.generate(pars.length, (index) => '\$${index+1}');
      String query = 'insert into $tableName VALUES(${placeholders.join(', ')})';

      final result = await conn.execute(
        query,
        parameters: pars,
      );
      setState(() {
        
      });
    }
    catch(e){
      print(e);
    }
  }

  Future<void> getTable(String tablename) async {
    try {
      final result = await conn.execute(
        'SELECT * FROM public.$tablename',
        
        );
      if (result.isNotEmpty) {
        setState(() {
          _tableData = result;
        });
        print(result);
      } else {
        print('No results');
        setState(() {
          _tableData = null;
        });
      }
    } catch (e) {
      print('Error: $e');
    }



  }
  Future<void> _showTableSelectionDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите таблицу'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTableSelectionButton(context, 'Student'),
              _buildTableSelectionButton(context, 'Dormitory'),
              _buildTableSelectionButton(context, 'Room'),
              _buildTableSelectionButton(context, 'Payment'),
              _buildTableSelectionButton(context, 'Occupancy'),
              _buildTableSelectionButton(context, 'Dormitory_has_Room'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('отмена'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedTable = result;
      });
    }
  }

  Widget _buildTableSelectionButton(BuildContext context, String tableName) {
    return ElevatedButton(
      onPressed: () {
        getTable(tableName);
        Navigator.of(context).pop(tableName);
      },
      child: Text(tableName),
    );
  }




  Future<void> _showInsertingDialog(BuildContext context) async {
    String? selectedOption;
    List<String> options = ['Student','Dormitory','Room','Dormitory_Has_Room','Occupancy','Payment'];
    Map<String, List<String>> inputFields = {
      'Student': ['id', 'name','surname','gender','age'],
      'Dormitory': ['id', 'adress', 'features'],
      'Room': ['id','capacity'],
      'Dormitory_Has_Room': ['room_id','dormitory_id'],
      'Occupancy': ['id','room_id','student_id','payment_id','dateStart','dateEnd'],
      'Payment':['id','amount','date','status']
    };
    List<TextEditingController> controllers = [];
    controllers.addAll(List.generate(inputFields.values.first.length, (_) => TextEditingController()));

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _InsertingDialog(
          controllers: controllers, 
          options: options,
          inputFields: inputFields,
          cb: _addData,
        );
      },
    );

    if (result != null) {
     
    }
  }
}






class TableWidget extends StatelessWidget {
  final List<List<dynamic>>? tableData;

  const TableWidget({Key? key, required this.tableData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tableData == null || tableData!.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _buildTableColumns(tableData![0]),
        rows: _buildTableRows(tableData!.sublist(1)),
      ),
    );
  }

  List<DataColumn> _buildTableColumns(List<dynamic> firstRow) {
    return firstRow.map<DataColumn>((item) => DataColumn(label: Text('$item'))).toList();
  }

  List<DataRow> _buildTableRows(List<List<dynamic>> rows) {
    return rows.map<DataRow>((row) {
      return DataRow(
        cells: row.map<DataCell>((item) => DataCell(Text('$item'))).toList(),
      );
    }).toList();
  }
}









class _InsertingDialog extends StatefulWidget {
  final List<String> options;
  final Map<String, List<String>> inputFields;
  final List<TextEditingController> controllers;
  final Future<void> Function(String, List<dynamic>) cb;
  _InsertingDialog({
    required this.options,
    required this.inputFields,
    required this.controllers,
    required this.cb,
  });

  @override
  __InsertingDialogState createState() => __InsertingDialogState();
}

class __InsertingDialogState extends State<_InsertingDialog> {
  String selectedOption='Student';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите таблицу'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField(
            value: selectedOption,
            items: widget.options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            hint: Text('Select an option'),
            onChanged: (value) {
              setState(() {
                selectedOption = value!;
                widget.controllers.clear();
                widget.controllers.addAll(List.generate(widget.inputFields[value]!.length, (_) => TextEditingController()));
              });
            },
          ),
          SizedBox(height: 10.0),
          if (selectedOption!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ввeдите значения',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Column(
                  children: List.generate(
                    widget.inputFields[selectedOption]!.length,
                    (index) => TextFormField(
                      controller: widget.controllers[index],
                      decoration: InputDecoration(
                        labelText: widget.inputFields[selectedOption]![index],
                      ),
                      onChanged: (value){
                        widget.controllers[index].text = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Закрыть'),
        ),
        ElevatedButton(
          onPressed: () {
            // List<dynamic> l = [];
            // for(int i = 0; i <widget.controllers.length; i++){
            //   l.add(widget.controllers[i].text);
            // } 
            final List<dynamic> l = widget.controllers.map((controller) => controller.text).toList();
            widget.cb(selectedOption, l);
          },
          child: const Text('Добавить'),
        )
      ],
    );
  }
}