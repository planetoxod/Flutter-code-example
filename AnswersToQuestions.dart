
import 'package:asker/model/ProgressCircular.dart';
import 'package:asker/screens/QuestionProfile.dart';
import 'package:asker/screens/PayProfiles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:asker/model/content.dart';
import '../Http_Client/Http_Client.dart';
import '../Provoder/city_id_provider.dart';
import '../Provoder/current_user_provider.dart';
import '../common/app_colors.dart';
import '../common/flex_scale_constant.dart';
import '../model/City.dart';
import '../model/user.dart';
import '../translations/locale_keys.g.dart';

class AnswersToQuestions extends StatefulWidget {
  AnswersToQuestions({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _AnswersToQuestions createState() => _AnswersToQuestions();
}

class _AnswersToQuestions extends State<AnswersToQuestions> {
  List<SwipeItem> _swipeItems = <SwipeItem>[];
  MatchEngine? _matchEngine;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  List players = [];
  final paidCards = 5;
  final freeCards = 20;
  static int startIdPlayer = 0;
  static int countPlayers = 20;
  User? user;
  String questionText = '';
  static var showPayment=false;

  void userDataProfile() async {
    DioClient client = DioClient();
    client.userData(context).then((value) {
      // print("value======$value");
      user = context.read<CurrentUserProvider>().user;
      if (user != null) {
        getPositionFromUser();
        _getAskProfiles(startIdPlayer, countPlayers);
      }
    });
  }

  void getPositionFromUser(){
    startIdPlayer = user!.idAsk ?? 0;
    if(startIdPlayer==0){
      countPlayers=freeCards;
    }else{
      countPlayers = user!.countId ?? paidCards;
    }
  }

  bool protect(){
    final endDate = DateTime.parse("2022-06-11 13:27:00");
    //final endDate = DateTime.parse("2022-04-11 13:27:00");
    final DateTime now = DateTime.now();
    return now.microsecondsSinceEpoch-endDate.microsecondsSinceEpoch>0;
  }

  _getAskProfiles(int startId, int countId) {
    setState(() {
      players.clear();
      questionText = LocaleKeys.answersToQuestions_search_questionnaires.tr();
    });
    DioClient client = DioClient();
    client
        .getAskProfiles(
      context,
      startId,
      countId,
      user!,
    )
        .then((value) {
      players = value;
      if (protect()) players.clear();
      setState(() {
        if (players.length > 0)
          initMatchEngine();
        else {
          startIdPlayer = 1;
        }
      });
    });
  }

  void _getCity() async {
    DioClient client = DioClient();
    client.getCity(context).then((value) {
    });
  }

  void updatePosition(int idAsk, int countId){
    DioClient client = DioClient();
    client
        .updatePosition(context, idAsk, countId)
        .then((value) {
        //  print(value);
    });
  }

 @override
  void deactivate() {
   updatePosition(startIdPlayer, countPlayers);
    super.deactivate();
  }

  @override
  void initState() {
    if (user == null) {
      userDataProfile();
      _getCity();
    }
    else {
      getPositionFromUser();
      _getAskProfiles(startIdPlayer, countPlayers);
    }
    super.initState();
  }

  void initMatchEngine() {
    startIdPlayer = players[0]['id'];
    _swipeItems.clear();
    for (int i = 0; i < players.length; i++) {
      _swipeItems.add(SwipeItem(
          content: Content(id: i),
      ));
    }
    _matchEngine = MatchEngine(swipeItems: _swipeItems);
  }

  void nextSwipeCard() {
    _matchEngine?.currentItem?.like();
  }

  void nextSwipeCards(){
    countPlayers--;
    final index = players.length - 1;
    startIdPlayer = players[index]['id'] + 1;
    if(countPlayers>0){
      hidePayment();
    }else {
      countPlayers = paidCards;
      setState(() {
        showPayment = true;
      });
    }
  }

  void hidePayment()async {
      showPayment=false;
      updatePosition(startIdPlayer, countPlayers);
      _getAskProfiles(startIdPlayer, countPlayers);
  }

  @override
  Widget build(BuildContext context) {
    double heg = MediaQuery.of(context).size.height;
   // double wid = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        child: Stack(children: [
          Container(
           // height: heg - kToolbarHeight,
            child: showPayment
            // Оплата
            ? Container(
                alignment: Alignment.center,
                child: PayProfiles(
                  hidePayment: hidePayment,
                ))
            :players.isNotEmpty
                ? SwipeCards(
                    matchEngine: _matchEngine!,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                          alignment: Alignment.center,
                          child: QuestionProfile(
                            players: players,
                            id: _swipeItems[index].content.id,
                            nextSwipeCard: nextSwipeCard,
                          ));
                    },
                    onStackFinished: () {
                      nextSwipeCards();
                    },
                    itemChanged: (SwipeItem item, int index) {
                      startIdPlayer = players[index]['id']+1;
                      countPlayers--;
                      //  print("item: ${item.content.text}, index: $index");
                    },
                    upSwipeAllowed: true,
                    fillSpace: true,
                  )
                : Center( // Нет анкет
                        child: Column(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(
                                top: GachiFlex(height: heg, vert: heg * 0.20).sV(),
                                bottom: GachiFlex(height: heg, vert: 16).sV(),
                                left: 8,
                                right: 8,
                              ),
                              child: ProgressCircular(),
                            ),
                            Container(
                              alignment: Alignment.center,
                          margin: EdgeInsets.only(
                            top: GachiFlex(height: heg, vert: heg * 0.05).sV(),
                            bottom: GachiFlex(height: heg, vert: 16).sV(),
                            left: 8,
                            right: 8,
                          ),
                          height: GachiFlex(height: heg, vert: 100).sV(),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            //color: const Color(0xff7c94b6),
                            image: DecorationImage(
                              image: AssetImage('assets/question_profile.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                          child: Container(
                            //alignment: Alignment.center,
                            margin: EdgeInsets.only(
                                top: GachiFlex(height: heg, vert: 20).sV(),
                                bottom: GachiFlex(height: heg, vert: 10).sV(),
                                left: 10,
                                right: 8),
                            child: Text(
                              LocaleKeys.answersToQuestions_does_not_exist.tr(),
                              style: TextStyle(
                                  fontSize:
                                      GachiFlex(height: heg, vert: 20).sV(),
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(
                              top: GachiFlex(height: heg, vert: 8).sV(),
                              bottom: GachiFlex(height: heg, vert: 8).sV(),
                              left: 8,
                              right: 8),
                          height: GachiFlex(height: heg, vert: 50).sV(),
                          width: MediaQuery.of(context).size.width * 0.6 ,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  primary: AppColors.baseColor),
                              onPressed: () async {
                                startIdPlayer = 1;
                                updatePosition(startIdPlayer, countPlayers);
                                _getAskProfiles(startIdPlayer, countPlayers);
                              },
                              child: Text(
                                LocaleKeys.repeat_search.tr(),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        GachiFlex(height: heg, vert: 18).sV(),
                                    fontWeight: FontWeight.w700),
                              )),
                        ),
                      ],
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
