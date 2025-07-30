import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/loader_widget.dart';
import '../../main.dart';
import '../../model/save_realestate_model.dart';
import '../../network/network_utils.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';
import '../../utils/images.dart';

class SaveRealEstateScreen extends StatefulWidget {
  const SaveRealEstateScreen({super.key});

  @override
  State<SaveRealEstateScreen> createState() => _SaveRealEstateScreenState();
}

class _SaveRealEstateScreenState extends State<SaveRealEstateScreen> {
  Future<List<SaveRealEstateModel>>? future;

  List<SaveRealEstateModel> savedList = [];

  @override
  void initState() {
    super.initState();
    fetchWishlist();
  }

  void fetchWishlist() {
    future = getWishlist();
  }

  Future<List<SaveRealEstateModel>> getWishlist() async {
    try {
      final response = await http.get(
        Uri.parse('${BASE_URL}get-saved-realestate/${appStore.userId}'),
        headers: buildHeaderTokens(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        savedList = data.map((e) => SaveRealEstateModel.fromJson(e)).toList();
        return savedList;
      } else {
        throw 'Failed to load saved properties';
      }
    } catch (e) {
      throw 'Error: ${e.toString()}';
    }
  }

  Future<void> saveOrUnsaveRealEstate(int serviceId) async {
    appStore.setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}save-unsave-realestate'),
        headers: buildHeaderTokens(),
        body: jsonEncode({
          'user_id': appStore.userId,
          'real_estate_services_id': serviceId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        String message = result['message'];

        if (message.toLowerCase().contains('unsave')) {
          savedList.removeWhere((element) => element.id == serviceId);
        }

        toast(message);
        setState(() {});
      } else {
        toast('Failed to save/unsave');
      }
    } catch (e) {
      toast('Error: $e');
    } finally {
      appStore.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return AppScaffold(
      appBarTitle: 'Wishlist',
      showLoader: false,
      child: Stack(
        children: [
          SnapHelperWidget<List<SaveRealEstateModel>>(
            future: future,
            loadingWidget: ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: 3,
              separatorBuilder: (_, __) => 16.height,
              itemBuilder: (_, __) => Container(
                height: height * 0.25,
                width: context.width(),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: Colors.grey.shade300,
                  borderRadius: radius(12),
                ),
              ),
            ),
            onSuccess: (snap) {
              return snap.isEmpty
                  ? NoDataWidget(
                      title: 'No saved Wishlist',
                      imageWidget: EmptyStateWidget(),
                      retryText: 'Reload',
                      onRetry: () {
                        fetchWishlist();
                        setState(() {});
                      },
                    )
                  : AnimatedListView(
                      padding: EdgeInsets.all(16),
                      itemCount: snap.length,
                      itemBuilder: (context, index) {
                        final model = snap[index];
                        final pageController = PageController();

                        return Card(
                          elevation: 0,
                          color: appStore.isDarkMode ? cardDarkColor : cardLightColor,
                          margin: EdgeInsets.only(bottom: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: model.images.isNotEmpty
                                        ? SizedBox(
                                            height: height * 0.2,
                                            child: PageView.builder(
                                              controller: pageController,
                                              itemCount: model.images.length,
                                              itemBuilder: (context, imgIndex) {
                                                return Image.network(
                                                  model.images[imgIndex],
                                                  width: double.infinity,
                                                  height: height * 0.2,
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            ),
                                          )
                                        : Container(
                                            height: height * 0.2,
                                            width: double.infinity,
                                            color: Colors.grey.shade300,
                                            child: Icon(Icons.image,
                                                size: width * 0.2),
                                          ),
                                  ),
                                  Positioned(
                                    top: width * 0.03,
                                    left: width * 0.03,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: width * 0.02,
                                          vertical: width * 0.015),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('RENT',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: width * 0.028)),
                                    ),
                                  ),
                                  Positioned(
                                    top: width * 0.03,
                                    right: width * 0.03,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child:
                                          Icon(Icons.share, size: width * 0.05),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: width * 0.03,
                                    right: width * 0.03,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: Icon(Icons.bookmark,
                                            color: primaryColor),
                                        onPressed: () =>
                                            saveOrUnsaveRealEstate(model.id),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: width * 0.025,
                                  horizontal: width * 0.02,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(model.title,
                                        style: boldTextStyle(size: 16)),
                                    4.height,
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: width * 0.04, color: Colors.grey),
                                        4.width,
                                        Expanded(
                                            child: Text(model.location,
                                                style: secondaryTextStyle())),
                                      ],
                                    ),
                                    12.height,
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.yellow[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: width * 0.025,
                                        horizontal: width * 0.02,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${model.areaSqfeet} Sqft',
                                              style: TextStyle(
                                                  fontSize: width * 0.03),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                          8.width,
                                          Expanded(
                                            child: Text(
                                              model.propertyType ?? '',
                                              style: TextStyle(
                                                  fontSize: width * 0.03),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                          8.width,
                                          Expanded(
                                            child: Text(
                                              model.ownerName ?? '',
                                              style: TextStyle(
                                                  fontSize: width * 0.03),
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Divider(height: 1),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text('₹${model.monthlyRent}',
                                        style: boldTextStyle(size: 16)),
                                    Spacer(),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFD4AF37),
                                        padding: EdgeInsets.symmetric(
                                             vertical: width * 0.03, horizontal: width * 0.05),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () async {
                                        final phone = model.ownerPhn
                                            ?.replaceAll(' ', '')
                                            .trim();
                                        if (phone != null && phone.isNotEmpty) {
                                          final Uri url =
                                              Uri(scheme: 'tel', path: phone);
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url);
                                          } else {
                                            toast('Could not open dialer');
                                          }
                                        } else {
                                          toast('Phone number not available');
                                        }
                                      },
                                      child: Text('Contact Owner',
                                          style:
                                              TextStyle(color: Colors.white, fontSize: width * 0.035)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
            },
            errorBuilder: (error) {
              return NoDataWidget(
                title: error,
                imageWidget: ErrorStateWidget(),
                retryText: 'Retry',
                onRetry: () {
                  fetchWishlist();
                  setState(() {});
                },
              );
            },
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
