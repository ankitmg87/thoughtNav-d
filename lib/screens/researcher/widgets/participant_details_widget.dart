import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:thoughtnav/constants/color_constants.dart';
import 'package:thoughtnav/screens/researcher/models/participant.dart';
import 'package:thoughtnav/services/firebase_firestore_service.dart';

// TODO -> Create disabled widget state
class ParticipantDetailsWidget extends StatefulWidget {
  const ParticipantDetailsWidget({
    Key key,
    this.participant,
    this.firebaseFirestoreService,
    this.studyUID,
  }) : super(key: key);

  final Participant participant;
  final FirebaseFirestoreService firebaseFirestoreService;
  final String studyUID;

  @override
  _ParticipantDetailsWidgetState createState() =>
      _ParticipantDetailsWidgetState();
}

class _ParticipantDetailsWidgetState extends State<ParticipantDetailsWidget> {
  Future<void> _updateParticipantDetails(
      String detailKey, dynamic detail) async {
    await widget.firebaseFirestoreService.updateParticipantDetails(
        widget.studyUID, widget.participant.participantUID, detailKey, detail);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 30.0,
          vertical: 20.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    height: 40.0,
                    width: 40.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(
                          'images/avatars/batman.png',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.participant.alias ?? 'Alias not set',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.0,
                          ),
                        ),
                        Text(
                          widget.participant.userName ?? 'Name not set',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          widget.participant.userGroupName ??
                              'Group unassigned',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                        Text(
                          widget.participant.lastSeen ??
                              'Last seen not available',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email: ${widget.participant.email}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Text(
                          'Phone: ${widget.participant.phone ?? 'Not set'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age: ${widget.participant.age ?? 'Unspecified'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Text(
                          'Gender: ${widget.participant.gender ?? 'Unspecified'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Responses: ${widget.participant.responses ?? 0}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        Text(
                          'Comments: ${widget.participant.comments ?? 0}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FlutterSwitch(
                              value: widget.participant.isActive,
                              onToggle: (bool value) async {
                                if (!widget.participant.isDeleted) {
                                  setState(() {
                                    widget.participant.isActive =
                                        !widget.participant.isActive;
                                  });
                                  await _updateParticipantDetails(
                                      'isActive', widget.participant.isActive);
                                }
                              },
                              height: 20.0,
                              width: 36.0,
                              padding: 4.0,
                              activeColor: PROJECT_GREEN,
                              inactiveColor: Colors.grey,
                              toggleSize: 14.0,
                            ),
                            SizedBox(
                              height: 6.0,
                            ),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              color: PROJECT_GREEN,
                            ),
                            SizedBox(
                              height: 2.0,
                            ),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          highlightColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () {
                            showGeneralDialog(
                              barrierDismissible: true,
                              barrierLabel: 'Delete Participant',
                              context: context,
                              pageBuilder: (BuildContext context,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation) {
                                return Center(
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.4,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.4,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.15,
                                            alignment: Alignment.bottomLeft,
                                            padding: EdgeInsets.all(30.0),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(4.0),
                                                topRight: Radius.circular(4.0),
                                              ),
                                              color: Colors.red[700],
                                            ),
                                            child: Text(
                                              'Delete Participant',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(30.0),
                                            child: Text(
                                              'If you choose to delete this participant: '
                                              '\n1. They will be removed from their assigned group. '
                                              '\n2. They won\'t be able to login.'
                                              '\n3. Their responses and comments will be visible to clients and moderators but not to other participants.',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(15.0),
                                            child: ButtonBar(
                                              children: [
                                                FlatButton(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14.0),
                                                    ),
                                                  ),
                                                  color: Colors.grey[200],
                                                ),
                                                SizedBox(
                                                  width: 4.0,
                                                ),
                                                FlatButton(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4.0),
                                                  ),
                                                  onPressed: () async {
                                                    await _updateParticipantDetails(
                                                        'isDeleted', true);
                                                    await _updateParticipantDetails(
                                                        'isActive', false);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14.0,
                                                      ),
                                                    ),
                                                  ),
                                                  color: Colors.red[700],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: PROJECT_GREEN,
                              ),
                              SizedBox(
                                height: 2.0,
                              ),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
