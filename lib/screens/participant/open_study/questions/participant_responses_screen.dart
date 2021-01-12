import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_storage/get_storage.dart';
import 'package:thoughtnav/constants/color_constants.dart';
import 'package:thoughtnav/constants/routes/routes.dart';
import 'package:thoughtnav/constants/string_constants.dart';
import 'package:thoughtnav/screens/participant/open_study/dashboard/dashboard_widgets/end_drawer_expansion_tile.dart';
import 'package:thoughtnav/screens/participant/open_study/questions/questions_widgets/question_and_description_container.dart';
import 'package:thoughtnav/screens/participant/open_study/questions/quick_intro_tutorial/quick_intro_tutorial_widgets/comment_widget.dart';
import 'package:thoughtnav/screens/participant/open_study/questions/quick_intro_tutorial/quick_intro_tutorial_widgets/participant_response_field.dart';
import 'package:thoughtnav/screens/researcher/models/comment.dart';
import 'package:thoughtnav/screens/researcher/models/participant.dart';
import 'package:thoughtnav/screens/researcher/models/question.dart';
import 'package:thoughtnav/screens/researcher/models/response.dart';
import 'package:thoughtnav/screens/researcher/models/topic.dart';
import 'package:thoughtnav/services/firebase_firestore_service.dart';
import 'package:thoughtnav/services/participant_firestore_service.dart';
import 'package:thoughtnav/services/participant_storage_service.dart';

import 'quick_intro_tutorial/quick_intro_tutorial_widgets/user_post_widget.dart';

class ParticipantResponseScreen extends StatefulWidget {
  @override
  _ParticipantResponseScreenState createState() =>
      _ParticipantResponseScreenState();
}

class _ParticipantResponseScreenState extends State<ParticipantResponseScreen> {
  final GlobalKey<ScaffoldState> _participantResponseScreenScaffoldKey =
      GlobalKey<ScaffoldState>();

  final _firebaseFirestoreService = FirebaseFirestoreService();

  final _participantFirestoreService = ParticipantFirestoreService();

  final _participantStorageService = ParticipantStorageService();

  TextEditingController _responseController;

  String _studyUID;
  String _participantUID;
  String _topicUID;
  String _questionUID;
  String _studyName;

  String _nextTopicUID;
  String _nextQuestionUID;

  bool isExpanded = false;
  bool showDrawer = false;
  bool _participantResponded = false;

  Participant _participant;
  Question _question;

  // Response _response = Response();
  Comment _comment = Comment();

  List<Topic> _studyNavigatorTopics;

  Future<void> _futureParticipant;
  Future<void> _futureStudyNavigatorTopics;
  Future<void> _futureQuestion;

  Stream<DocumentSnapshot> _questionStream;

  Stream<QuerySnapshot> _responsesStream;

  void _unAwaited(Future<void> future) {}

  Future<void> _getStudyNavigatorTopics(String studyUID) async {
    _studyNavigatorTopics = await _participantFirestoreService
        .getParticipantTopics(_studyUID, _participant.groupUID);
  }

  void _setNextQuestionUIDAndNextTopicUID() {
    var topicIndex = _studyNavigatorTopics.indexWhere((topic) {
      if (topic.topicUID == _topicUID) {
        var questionIndex = topic.questions.indexWhere((question) {
          if (question.questionUID == _questionUID) {
            return true;
          } else {
            return false;
          }
        });
        if (questionIndex != -1) {
          if (topic.questions.length - 1 >= questionIndex + 1) {
            _nextQuestionUID = topic.questions[questionIndex + 1].questionUID;
            _nextTopicUID = topic.topicUID;
          } else {
            _nextQuestionUID = 'lastQuestionInThisTopic';
          }
        }
        return true;
      } else {
        return false;
      }
    });

    if (_nextQuestionUID == 'lastQuestionInThisTopic') {
      if (topicIndex != -1) {
        if (_studyNavigatorTopics.length - 1 >= topicIndex + 1) {
          _nextTopicUID = _studyNavigatorTopics[topicIndex + 1].topicUID;
          _nextQuestionUID =
              _studyNavigatorTopics[topicIndex + 1].questions.first.questionUID;
        } else {
          _nextTopicUID = 'lastTopicInThisStudy';
        }
      }
    }
  }

  Future<void> _getParticipant(String studyUID, String participantUID) async {
    _participant = await _firebaseFirestoreService.getParticipant(
        studyUID, participantUID);

    _futureStudyNavigatorTopics = _getStudyNavigatorTopics(_studyUID);
  }

  Future<void> _getQuestion(String topicUID, String questionUID) async {
    _question = await _firebaseFirestoreService.getQuestion(
        _studyUID, topicUID, questionUID);

    if (_question.respondedBy != null) {
      if (_question.respondedBy.contains(_participantUID)) {
        _participantResponded = true;
      } else {
        _participantResponded = false;
      }
    } else {
      _participantResponded = false;
    }

    _questionStream =
        _getQuestionStream(_studyUID, topicUID, questionUID, _participantUID);
  }

  Stream<QuerySnapshot> _getResponsesStream(
      String studyUID, String topicUID, String questionUID) {
    return _participantFirestoreService.getResponses(
        studyUID, topicUID, questionUID);
  }

  Stream<DocumentSnapshot> _getQuestionStream(String studyUID, String topicUID,
      String questionUID, String participantUID) {
    return _participantFirestoreService.streamRespondedBy(
        studyUID, topicUID, questionUID, participantUID);
  }

  void _continueToNextQuestion(String nextTopicUID, String nextQuestionUID) {
    setState(() {
      _topicUID = nextTopicUID;
      _questionUID = nextQuestionUID;

      _futureStudyNavigatorTopics = _getStudyNavigatorTopics(_studyUID);
      _futureQuestion = _getQuestion(nextTopicUID, nextQuestionUID);
      _responsesStream =
          _getResponsesStream(_studyUID, nextTopicUID, nextQuestionUID);
    });
  }

  @override
  void initState() {
    var getStorage = GetStorage();

    _studyUID = getStorage.read('studyUID');
    _participantUID = getStorage.read('participantUID');
    _studyName = getStorage.read('studyName');

    _futureParticipant = _getParticipant(_studyUID, _participantUID);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Map<String, String> arguments = ModalRoute.of(context).settings.arguments;

    if (arguments == null) {
      SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.of(context).popAndPushNamed(LOGIN_SCREEN);
      });
    }

    if (arguments != null) {
      _topicUID = arguments['topicUID'];
      _questionUID = arguments['questionUID'];
    }

    if (_topicUID != null ||
        _topicUID.isNotEmpty &&
            _questionUID != null &&
            _questionUID.isNotEmpty) {
      _futureQuestion = _getQuestion(_topicUID, _questionUID);
      _responsesStream =
          _getResponsesStream(_studyUID, _topicUID, _questionUID);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (screenSize.width < screenSize.height) {
      return buildPhoneScaffold(context, screenSize);
    } else {
      return _desktopScaffoldFutureBuilder();
    }
  }

  FutureBuilder _desktopScaffoldFutureBuilder() {
    return FutureBuilder(
      future: _futureParticipant,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return Material(
              child: Center(
                child: Text(
                  'Something went wrong.',
                ),
              ),
            );
            break;
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Material(
              child: Center(
                child: Text('Loading...'),
              ),
            );
            break;
          case ConnectionState.done:
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.white,
                centerTitle: true,
                title: Text(
                  _studyName,
                  style: TextStyle(
                    color: TEXT_COLOR,
                  ),
                ),
                leadingWidth: 120.0,
                leading: Center(
                  child: InkWell(
                    onTap: () async {
                      if (_responseController == null) {
                        _unAwaited(Navigator.of(context)
                            .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                      }

                      if (_responseController != null) {
                        if (_responseController.text.isNotEmpty) {
                          await showGeneralDialog(
                              barrierDismissible: false,
                              barrierLabel: 'Are you sure',
                              context: context,
                              pageBuilder: (BuildContext exitDialogContext,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation) {
                            return Center(
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.3
                                ),
                                child: Material(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confirm Exit',
                                          style: TextStyle(
                                            color: Colors.grey[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Align(
                                          child: Container(
                                            height: 1.0,
                                            width: double.maxFinite,
                                            color: Colors.grey,
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                                  0.3,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Text(
                                          'The response which has\'nt been posted will be lost.',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30.0,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              RaisedButton(
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pop();
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'CANCEL',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10.0,
                                              ),
                                              RaisedButton(
                                                color: Colors.red[700],
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pushNamedAndRemoveUntil(
                                                      PARTICIPANT_DASHBOARD_SCREEN,
                                                          (route) => false);
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'EXIT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                      } else {
                      _unAwaited(Navigator.of(context)
                          .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                      }
                    }
                    },
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: Text(
                      APP_NAME,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ),
                actions: [
                  InkWell(
                    onTap: () async {
                      if (_responseController == null) {
                        _unAwaited(Navigator.of(context)
                            .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                      }

                      if (_responseController != null) {
                        if (_responseController.text.isNotEmpty) {
                          await showGeneralDialog(
                              barrierDismissible: false,
                              barrierLabel: 'Are you sure',
                              context: context,
                              pageBuilder: (BuildContext exitDialogContext,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation) {
                            return Center(
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.3
                                ),
                                child: Material(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confirm Exit',
                                          style: TextStyle(
                                            color: Colors.grey[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Align(
                                          child: Container(
                                            height: 1.0,
                                            width: double.maxFinite,
                                            color: Colors.grey,
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                                  0.3,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Text(
                                          'The response which has\'nt been posted will be lost.',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30.0,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              RaisedButton(
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pop();
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'CANCEL',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10.0,
                                              ),
                                              RaisedButton(
                                                color: Colors.red[700],
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pushNamedAndRemoveUntil(
                                                      PARTICIPANT_DASHBOARD_SCREEN,
                                                          (route) => false);
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'EXIT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                      } else {
                      _unAwaited(Navigator.of(context)
                          .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                      }
                    }
                    },
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: Text(
                            'Go To Dashboard',
                            style: TextStyle(
                              color: TEXT_COLOR.withOpacity(0.7),
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: 14.0,
                          color: TEXT_COLOR.withOpacity(0.8),
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              body: Row(
                children: [
                  _buildStudyNavigator(),
                  Expanded(
                    child: FutureBuilder(
                      future: _futureQuestion,
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return Center(
                              child: Text('Something went wrong'),
                            );
                            break;
                          case ConnectionState.waiting:
                          case ConnectionState.active:
                            return Center(
                              child: Text('Loading...'),
                            );
                            break;
                          case ConnectionState.done:
                            return ListView(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 10.0,
                                  color: PROJECT_GREEN.withOpacity(0.2),
                                ),
                                QuestionAndDescriptionContainer(
                                  screenSize: MediaQuery.of(context).size,
                                  number: _question.questionNumber,
                                  title: _question.questionTitle,
                                  description: _question.questionStatement,
                                ),
                                SizedBox(
                                  height: 40.0,
                                ),
                                StreamBuilder<DocumentSnapshot>(
                                  stream: _questionStream,
                                  builder: (BuildContext context,
                                      AsyncSnapshot<DocumentSnapshot>
                                          snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return SizedBox();
                                        break;
                                      case ConnectionState.waiting:
                                        return SizedBox();
                                        break;
                                      case ConnectionState.active:
                                        if (snapshot.hasData) {
                                          if (snapshot.data
                                              .data()['respondedBy']
                                              .contains(_participantUID)) {
                                            _participantResponded = true;
                                            return Text(
                                              'Your response has been posted.\n'
                                              'Please read and comment on other posts.\n'
                                              'Scroll to the bottom to continue',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          } else {
                                            _responseController =
                                                TextEditingController();

                                            var response = Response(
                                              questionHasMedia:
                                                  _question.hasMedia,
                                            );

                                            print(response.questionHasMedia);

                                            return ParticipantResponseField(
                                              studyName: _studyName,
                                              participant: _participant,
                                              question: _question,
                                              topicUID: _topicUID,
                                              responseController:
                                                  _responseController,
                                              response: response,
                                              onTap: () async {
                                                response.responseUID = '';
                                                response.questionNumber =
                                                    _question.questionNumber;
                                                response.questionTitle =
                                                    _question.questionTitle;
                                                response.participantUID =
                                                    _participantUID;
                                                response.participantDisplayName =
                                                    _participant.displayName;
                                                response.avatarURL =
                                                    _participant
                                                        .profilePhotoURL;
                                                response.claps = [];
                                                response.comments = 0;
                                                response.hasMedia ??= false;
                                                response.userName =
                                                    '${_participant.userFirstName} ${_participant.userLastName}';
                                                response.responseTimestamp =
                                                    Timestamp.now();

                                                await _participantFirestoreService
                                                    .postResponse(
                                                        _studyUID,
                                                        _topicUID,
                                                        _question.questionUID,
                                                        response);

                                                setState(() {
                                                  _responseController = null;
                                                  _futureStudyNavigatorTopics =
                                                      _getStudyNavigatorTopics(
                                                          _studyUID);
                                                });
                                              },
                                            );
                                          }
                                        } else {
                                          return Text('1');
                                        }
                                        break;
                                      case ConnectionState.done:
                                        return SizedBox();
                                        break;
                                      default:
                                        return SizedBox();
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 20.0,
                                ),
                                StreamBuilder<QuerySnapshot>(
                                  stream: _responsesStream,
                                  builder: (BuildContext context,
                                      AsyncSnapshot<QuerySnapshot> snapshot) {
                                    switch (snapshot.connectionState) {
                                      case ConnectionState.none:
                                        return SizedBox();
                                        break;
                                      case ConnectionState.waiting:
                                      case ConnectionState.active:
                                        if (snapshot.hasData) {
                                          var responses = snapshot.data.docs;

                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 40.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        height: 1.0,
                                                        color: Colors.grey[300],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10.0,
                                                    ),
                                                    Text(
                                                      'All Responses',
                                                      style: TextStyle(
                                                        color:
                                                            PROJECT_NAVY_BLUE,
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                height: 20.0,
                                              ),
                                              ListView.builder(
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: responses.length,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  var commentController =
                                                      TextEditingController();

                                                  var response =
                                                      Response.fromMap(
                                                          responses[index]
                                                              .data());

                                                  if (responses[index]
                                                          ['responseUID'] !=
                                                      null) {
                                                    try {
                                                      return UserResponseWidget(
                                                        participant:
                                                            _participant,
                                                        topicUID: _topicUID,
                                                        questionUID:
                                                            _questionUID,
                                                        response: response,
                                                      );
                                                    } catch (e) {
                                                      print(e);
                                                      return SizedBox();
                                                    }
                                                  } else {
                                                    return SizedBox();
                                                  }
                                                },
                                              )
                                            ],
                                          );
                                        } else if (snapshot.data == null) {
                                          return Center(
                                            child: Text('No responses yet'),
                                          );
                                        } else {
                                          return Center(
                                            child: Text('No responses yet'),
                                          );
                                        }
                                        break;
                                      case ConnectionState.done:
                                      default:
                                        return Center(
                                          child: Text('No responses yet'),
                                        );
                                    }
                                  },
                                ),
                                SizedBox(
                                  height: 40.0,
                                ),
                                _participantResponded
                                    ? Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 40.0),
                                          child: FlatButton(
                                            onPressed: () {
                                              if (_nextTopicUID ==
                                                      'lastTopicInThisStudy'
                                                  // _nextQuestionUID ==
                                                  //     'lastQuestionInThisStudy'
                                                  ) {
                                                Navigator.of(context)
                                                    .popAndPushNamed(
                                                        PARTICIPANT_DASHBOARD_SCREEN);
                                              } else {
                                                _continueToNextQuestion(
                                                    _nextTopicUID,
                                                    _nextQuestionUID);
                                              }
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 12.0,
                                              ),
                                              child: Text(
                                                'CONTINUE',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            color: PROJECT_GREEN,
                                          ),
                                        ),
                                      )
                                    : SizedBox(),
                                SizedBox(
                                  height: 20.0,
                                ),
                              ],
                            );
                            break;
                          default:
                            return SizedBox();
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
            break;
          default:
            return SizedBox();
        }
      },
    );
  }

  Align _buildStudyNavigator() {
    return Align(
      child: Container(
        color: Colors.white,
        constraints: BoxConstraints(
          maxWidth: 300.0,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Study Navigator',
                maxLines: 1,
                style: TextStyle(
                  color: TEXT_COLOR,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () async {
                  if (_responseController == null) {
                    _unAwaited(Navigator.of(context)
                        .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                  }

                  if (_responseController != null) {
                    if (_responseController.text.isNotEmpty) {
                      await showGeneralDialog(
                          barrierDismissible: false,
                          barrierLabel: 'Are you sure',
                          context: context,
                          pageBuilder: (BuildContext exitDialogContext,
                              Animation<double> animation,
                              Animation<double> secondaryAnimation) {
                            return Center(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.3
                                ),
                                child: Material(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Confirm Exit',
                                          style: TextStyle(
                                            color: Colors.grey[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Align(
                                          child: Container(
                                            height: 1.0,
                                            width: double.maxFinite,
                                            color: Colors.grey,
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Text(
                                          'The response which has\'nt been posted will be lost.',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 30.0,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              RaisedButton(
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pop();
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'CANCEL',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10.0,
                                              ),
                                              RaisedButton(
                                                color: Colors.red[700],
                                                onPressed: () {
                                                  Navigator.of(exitDialogContext)
                                                      .pushNamedAndRemoveUntil(
                                                          PARTICIPANT_DASHBOARD_SCREEN,
                                                          (route) => false);
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(10.0),
                                                  child: Text(
                                                    'EXIT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12.0,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                    } else {
                      _unAwaited(Navigator.of(context)
                          .popAndPushNamed(PARTICIPANT_DASHBOARD_SCREEN));
                    }
                  }
                },
                highlightColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        color: TEXT_COLOR,
                        size: 14.0,
                      ),
                      SizedBox(
                        width: 10.0,
                      ),
                      Text(
                        'Go back to dashboard',
                        style: TextStyle(
                          color: TEXT_COLOR,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FutureBuilder(
              future: _futureStudyNavigatorTopics,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return SizedBox();
                    break;
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    return Center(
                      child: Text('Loading topics...'),
                    );
                    break;
                  case ConnectionState.done:
                    if (_studyNavigatorTopics.isNotEmpty) {
                      _setNextQuestionUIDAndNextTopicUID();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: _studyNavigatorTopics.length,
                        itemBuilder: (BuildContext context, int topicIndex) {
                          if (topicIndex == 0) {
                            return _buildDesktopStudyNavigatorExpansionTile(
                              topicIndex,
                              _studyNavigatorTopics[topicIndex],
                              _participantUID,
                            );
                          } else {
                            if (_studyNavigatorTopics[topicIndex - 1]
                                    .questions
                                    .last
                                    .respondedBy !=
                                null) {
                              if (_studyNavigatorTopics[topicIndex - 1]
                                  .questions
                                  .last
                                  .respondedBy
                                  .contains(_participantUID)) {
                                return _buildDesktopStudyNavigatorExpansionTile(
                                    topicIndex,
                                    _studyNavigatorTopics[topicIndex],
                                    _participantUID);
                              } else {
                                return ListTile(
                                  onTap: () {
                                    showGeneralDialog(
                                      context: context,
                                      barrierLabel: 'Locked Topic Dialog',
                                      barrierDismissible: true,
                                      pageBuilder: (BuildContext context,
                                          Animation<double> animation,
                                          Animation<double>
                                              secondaryAnimation) {
                                        return Center(
                                          child: Material(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Text(
                                                'All Previous questions must be answered',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20.0,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  title: Text(
                                    'Topic Locked',
                                  ),
                                );
                              }
                            } else {
                              return ListTile(
                                onTap: () {
                                  showGeneralDialog(
                                    context: context,
                                    barrierLabel: 'Locked Topic Dialog',
                                    barrierDismissible: true,
                                    pageBuilder: (BuildContext context,
                                        Animation<double> animation,
                                        Animation<double> secondaryAnimation) {
                                      return Center(
                                        child: Material(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.all(20.0),
                                            child: Text(
                                              'All Previous questions must be answered',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20.0,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                title: Text(
                                  'Topic Locked',
                                ),
                              );
                            }
                          }
                        },
                      );
                    } else {
                      return SizedBox();
                    }
                    break;
                  default:
                    return SizedBox();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStudyNavigatorExpansionTile(
      int topicIndex, Topic topic, String participantUID) {
    return Theme(
      data: ThemeData(
          unselectedWidgetColor: Colors.black, accentColor: PROJECT_GREEN),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          topic.topicName,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
        children: [
          SizedBox(
            height: 10.0,
          ),
          ListView.separated(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 10.0,
            ),
            shrinkWrap: true,
            itemCount: topic.questions.length,
            itemBuilder: (BuildContext context, int questionIndex) {
              if (questionIndex == 0) {
                // _setNextTopicAndNextQuestionUIDs(
                //     _studyNavigatorTopics, topicIndex, questionIndex);
                return _buildDesktopStudyNavigatorActiveQuestion(
                  topic.questions[questionIndex],
                  topic.topicUID,
                );
              } else {
                if (topic.questions[questionIndex - 1].respondedBy != null) {
                  if (topic.questions[questionIndex - 1].respondedBy
                      .contains(participantUID)) {
                    // _setNextTopicAndNextQuestionUIDs(
                    //     _studyNavigatorTopics, topicIndex, questionIndex);

                    return _buildDesktopStudyNavigatorActiveQuestion(
                      topic.questions[questionIndex],
                      topic.topicUID,
                    );
                  } else {
                    return _buildDesktopStudyNavigatorLockedQuestion(
                        topic.questions[questionIndex]);
                  }
                } else {
                  return _buildDesktopStudyNavigatorLockedQuestion(
                      topic.questions[questionIndex]);
                }
              }
            },
            separatorBuilder: (BuildContext context, int index) {
              return SizedBox(height: 20.0);
            },
          ),
          SizedBox(
            height: 20.0,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStudyNavigatorActiveQuestion(
      Question question, String topicUID) {
    return InkWell(
      onTap: () {
        setState(() {
          _topicUID = topicUID;
          _questionUID = question.questionUID;

          _futureQuestion = _getQuestion(topicUID, question.questionUID);
          _responsesStream =
              _getResponsesStream(_studyUID, topicUID, question.questionUID);
        });
      },
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${question.questionNumber}  ${question.questionTitle}',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 13.0,
              ),
            ),
            Icon(
              question.respondedBy == null
                  ? Icons.arrow_forward
                  : question.respondedBy.contains(_participantUID)
                      ? Icons.check_circle_outline_rounded
                      : Icons.arrow_forward,
              color: PROJECT_GREEN,
              size: 14.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStudyNavigatorLockedQuestion(Question question) {
    return InkWell(
      onTap: () {
        showGeneralDialog(
            barrierDismissible: true,
            barrierLabel: 'Respond to questions',
            context: context,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return Center(
                child: Material(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Please respond to previous questions',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              );
            });
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '${question.questionNumber}  Question Locked',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.lock,
              color: Colors.grey[800],
              size: 13.0,
            ),
          ],
        ),
      ),
    );
  }

  Scaffold buildPhoneScaffold(BuildContext context, Size screenSize) {
    return Scaffold(
      key: _participantResponseScreenScaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF333333),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          APP_NAME,
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: PROJECT_GREEN,
            ),
            onPressed: () => _participantResponseScreenScaffoldKey.currentState
                .openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildPhoneEndDrawer(),
      body: FutureBuilder(
        future: _futureQuestion,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return Center(
                child: Text(
                  'Something went wrong.',
                ),
              );
              break;
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Center(
                child: Text('Loading...'),
              );
              break;
            case ConnectionState.done:
              return ListView(
                children: [
                  Container(
                    width: double.infinity,
                    height: 10.0,
                    color: PROJECT_GREEN.withOpacity(0.2),
                  ),
                  QuestionAndDescriptionContainer(
                    screenSize: MediaQuery.of(context).size,
                    number: _question.questionNumber,
                    title: _question.questionTitle,
                    description: _question.questionStatement,
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  // ParticipantResponseField(
                  //   participant: _participant,
                  //   response: _response,
                  //   onTap: () async {
                  //     // _response.timeElapsed = '0';
                  //     _response.participantDisplayName =
                  //         _participant.displayName;
                  //     _response.claps = [];
                  //     _response.participantUID = _participantUID;
                  //     _response.responseTimestamp = Timestamp.now();
                  //     _response.userName = _participant.userFirstName;
                  //     _response.avatarURL = _participant.profilePhotoURL;
                  //     _response.comments = 0;
                  //     _response.questionNumber = _question.questionNumber;
                  //     _response.questionTitle = _question.questionTitle;
                  //     // await _postResponse(_studyUID, );
                  //   },
                  // ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
                    child: Text(
                      'All responses',
                      style: TextStyle(
                        color: TEXT_COLOR.withOpacity(0.5),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder(
                    stream:
                        _getResponsesStream(_studyUID, _topicUID, _questionUID),
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.none:
                          return SizedBox();
                          break;
                        case ConnectionState.waiting:
                        case ConnectionState.active:
                          if (snapshot.hasData) {
                            var responses = snapshot.data.documents;

                            return ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: responses.length,
                              itemBuilder: (BuildContext context, int index) {
                                return SizedBox();
                              },
                            );
                          } else if (snapshot.data == null) {
                            return Center(
                              child: Text('No responses yet'),
                            );
                          } else {
                            return Center(
                              child: Text('No responses yet'),
                            );
                          }
                          break;
                        case ConnectionState.done:
                        default:
                          return Center(
                            child: Text('No responses yet'),
                          );
                      }
                    },
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            onPressed: () => Navigator.of(context)
                                .pushNamed(TOPIC_COMPLETE_SCREEN),
                            color: PROJECT_GREEN,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 40.0,
                  ),
                ],
              );
              break;
            default:
              return SizedBox();
          }
        },
      ),
    );
  }

  Drawer _buildPhoneEndDrawer() {
    return Drawer(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Color(0xFF333333),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Study Navigator',
                  style: TextStyle(
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            height: 1.0,
            color: Color(0xFFE5E5E5),
            margin: EdgeInsets.only(
              top: 5.0,
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _futureStudyNavigatorTopics,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    return Center(
                      child: Text('Loading Topics...'),
                    );
                    break;
                  case ConnectionState.done:
                    if (_studyNavigatorTopics != null) {
                      return ListView.builder(
                        itemCount: _studyNavigatorTopics.length,
                        itemBuilder: (BuildContext context, int index) {
                          return EndDrawerExpansionTile(
                            title: _studyNavigatorTopics[index].topicName,
                            questions: _studyNavigatorTopics[index].questions,
                          );
                        },
                      );
                    } else {
                      return Center(
                        child: Text('Some error occurred'),
                      );
                    }
                    break;
                  default:
                    return SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Also Post this confirmation we would like to set a meeting on late evening 4th jan to proceed to researcher section
