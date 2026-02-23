// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ApiConfig/KnApiConfig.dart';
import '../../CommonProcess/customUI/KnAppBar.dart';
import '../../CommonProcess/customUI/KnLoadingIndicator.dart'; // 导入自定义加载指示器
import '../../Constants.dart';
import '../../theme/theme_extensions.dart'; // [Flutter页面主题改造] 2026-01-21 添加主题扩展
import 'Kn03D003BnkBean.dart';
import 'kn03D003Bank_add_edit.dart';
import 'kn03D003Stubnk_list.dart';

// ignore: must_be_immutable
class BankViewPage extends StatefulWidget {
  final Color knBgColor;
  final Color knFontColor;
  late String pagePath;
  // titleName を追加
  late final String titleName;
  BankViewPage({
    super.key,
    required this.knBgColor,
    required this.knFontColor,
    required this.pagePath,
  });

  @override
  _BankViewPageState createState() => _BankViewPageState();
}

class _BankViewPageState extends State<BankViewPage> {
  final String titleName = "银行信息一览";
  late String subtitle;
  late Future<List<Kn03D003BnkBean>> futureBanks;
  bool _isLoading = false; // 添加加载状态变量

  @override
  void initState() {
    super.initState();
    _fetchBankData();
  }

  // 统一的数据加载方法
  void _fetchBankData() {
    setState(() {
      _isLoading = true; // 开始加载前设置为true
    });

    futureBanks = _fetchBanks().then((result) {
      // 数据加载完成后
      setState(() {
        _isLoading = false; // 加载完成后设置为false
      });
      return result;
    }).catchError((error) {
      // 发生错误时
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });
      throw error; // 继续传递错误
    });
  }

  // 画面初期化：取得所有银行信息
  Future<List<Kn03D003BnkBean>> _fetchBanks() async {
    // 上课管理菜单画面，点击"学生科目管理"按钮的url请求
    final String apiUrl = '${KnConfig.apiBaseUrl}${Constants.bankView}';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> banksJson = json.decode(decodedBody);
      return banksJson.map((json) => Kn03D003BnkBean.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load banks');
    }
  }

  @override
  Widget build(BuildContext context) {
    subtitle = "${widget.pagePath} >> $titleName";
    return Scaffold(
      appBar: KnAppBar(
        title: titleName,
        subtitle: subtitle,
        context: context,
        appBarBackgroundColor: widget.knBgColor,
        titleColor: Color.fromARGB(
            widget.knFontColor.alpha,
            widget.knFontColor.red - 20,
            widget.knFontColor.green - 20,
            widget.knFontColor.blue - 20),
        // [Flutter页面主题改造] 2026-01-26 副标题背景使用主题色的深色版本
        subtitleBackgroundColor: Color.fromARGB(
            widget.knBgColor.alpha,
            (widget.knBgColor.red * 0.6).round(),
            (widget.knBgColor.green * 0.6).round(),
            (widget.knBgColor.blue * 0.6).round()),
        subtitleTextColor: Colors.white,
        titleFontSize: 20.0,
        subtitleFontSize: 12.0,
        addInvisibleRightButton: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            // 新規"➕"按钮的事件处理函数
            onPressed: _isLoading
                ? null // 如果正在加载，禁用按钮
                : () {
                    // Navigate to add bank page or handle add operation
                    Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BankAddEdit(
                                  showMode: '新規',
                                  knBgColor: widget.knBgColor,
                                  knFontColor: widget.knFontColor,
                                  pagePath: subtitle,
                                ))).then((value) => {
                          if (value == true)
                            {
                              _fetchBankData() // 使用统一的加载方法
                            }
                        });
                  },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 原有的FutureBuilder
          FutureBuilder<List<Kn03D003BnkBean>>(
            future: futureBanks,
            builder: (context, snapshot) {
              if (_isLoading ||
                  snapshot.connectionState == ConnectionState.waiting) {
                // 当正在加载或连接状态是等待中时，返回空容器，因为我们有单独的加载指示器
                return Container();
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _buildBankItem(snapshot.data![index]);
                  },
                );
              } else {
                // 在非加载状态下，如果没有数据且没有错误，显示空容器
                return Container();
              }
            },
          ),

          // 加载指示器层
          if (_isLoading)
            Center(
              child:
                  KnLoadingIndicator(color: widget.knBgColor), // 使用自定义的加载器进度条
            ),
        ],
      ),
    );
  }

  Widget _buildBankItem(Kn03D003BnkBean bank) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundImage: AssetImage('images/student-placeholder.png'),
        ),
        title: Text(bank.bankName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 编辑按钮
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              // 编辑按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BankAddEdit(
                            bank: bank,
                            showMode: '編集',
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                            pagePath: subtitle,
                          ),
                        ),
                      ).then((value) {
                        // 检查返回值，如果为true，则重新加载数据
                        if (value == true) {
                          _fetchBankData(); // 使用统一的加载方法
                        }
                      });
                    },
            ),

            // 删除按钮
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () async {
                      // [Flutter页面主题改造] 2026-01-21 使用主题字体样式
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('删除确认',
                                style: KnElementTextStyle.dialogTitle(context,
                                    color: Constants.stuDocThemeColor)),
                            content: Text('确定要删除【${bank.bankName}】这门科目吗？',
                                style: KnElementTextStyle.dialogContent(context)),
                            actions: <Widget>[
                              TextButton(
                                child: Text('取消',
                                    style: KnElementTextStyle.buttonText(context,
                                        color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                              TextButton(
                                child: Text('确定',
                                    style: KnElementTextStyle.buttonText(context,
                                        color: Constants.stuDocThemeColor)),
                                onPressed: () {
                                  deleteBank(bank);
                                  Navigator.of(context).pop(); // 关闭对话框
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
            ),

            // 追加银行所属学生按钮
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.blue),
              // 银行所属学生按钮的事件处理函数
              onPressed: _isLoading
                  ? null // 如果正在加载，禁用按钮
                  : () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BankStuPageView(
                            bankName: bank.bankName,
                            bankId: bank.bankId,
                            knBgColor: widget.knBgColor,
                            knFontColor: widget.knFontColor,
                            pagePath: subtitle,
                          ),
                        ),
                      ).then((value) {
                        // 检查返回值，如果为true，则重新加载数据
                        if (value == true) {
                          _fetchBankData(); // 使用统一的加载方法
                        }
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  deleteBank(Kn03D003BnkBean bank) {
    setState(() {
      _isLoading = true; // 开始删除操作前设置为true
    });

    final String apiUrl =
        '${KnConfig.apiBaseUrl}${Constants.stuBankDelete}/${bank.bankId}';
    try {
      http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json', // 添加内容类型头
        },
      ).then((response) {
        setState(() {
          _isLoading = false; // 操作完成后设置为false
        });

        if (response.statusCode == 200) {
          _fetchBankData(); // 使用统一的加载方法
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('删除失败'),
                content: Text(response.body),
                actions: <Widget>[
                  TextButton(
                    child: const Text('确定'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          );
        }
      }).catchError((error) {
        setState(() {
          _isLoading = false; // 出错时也要设置为false
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('操作异常'),
              content: Text('发生错误: $error'),
              actions: <Widget>[
                TextButton(
                  child: const Text('确定'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // 出错时也要设置为false
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('网络异常'),
            content: const Text('无法连接到服务器'),
            actions: <Widget>[
              TextButton(
                child: const Text('确定'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  // 不再需要reloadData方法，统一使用_fetchBankData
}
