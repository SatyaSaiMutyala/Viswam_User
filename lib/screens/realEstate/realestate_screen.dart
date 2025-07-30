import 'dart:convert';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/loader_widget.dart';
import '../../model/get_all_realestate.dart';
import '../../network/network_utils.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';

class RealEstateScreen extends StatefulWidget {
  const RealEstateScreen({super.key});

  @override
  State<RealEstateScreen> createState() => _RealEstateScreenState();
}

class _RealEstateScreenState extends State<RealEstateScreen> {
  ScrollController scrollController = ScrollController();

  List<RealEstateModel> realEstates = [];
  List<int> savedIds = [];
  bool isLoading = false;
  bool isLastPage = false;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    fetchSavedIds();
    fetchRealEstates();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 100 &&
          !isLoading &&
          !isLastPage) {
        currentPage++;
        fetchRealEstates();
      }
    });
  }

  Future<void> fetchSavedIds() async {
    try {
      final savedRes = await http.get(
        Uri.parse('${BASE_URL}get-saved-realestate/${appStore.userId}'),
        headers: buildHeaderTokens(),
      );

      if (savedRes.statusCode == 200) {
        final List savedData = jsonDecode(savedRes.body)['data'];
        savedIds = savedData.map((e) => e['id'] as int).toList();
      }
    } catch (e) {
      log('Saved ID fetch error: $e');
    }
  }

  Future<void> fetchRealEstates() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${BASE_URL}get-all-realestate?page=$currentPage'),
        headers: buildHeaderTokens(),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(res.body);
        final List<dynamic> data = jsonData['data'];
        final int lastPage = jsonData['last_page'];

        realEstates
            .addAll(data.map((e) => RealEstateModel.fromJson(e)).toList());

        if (currentPage >= lastPage) isLastPage = true;
      } else {
        toast('Failed to load data.');
      }
    } catch (e) {
      toast('Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Real Estate',
      child: Observer(
        builder: (_) => Stack(
          children: [
            realEstates.isEmpty && isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    separatorBuilder: (_, __) => 16.height,
                    itemBuilder: (_, __) => Container(
                      height: 200,
                      decoration: boxDecorationWithRoundedCorners(
                        backgroundColor: Colors.grey.shade300,
                        borderRadius: radius(12),
                      ),
                    ),
                  )
                : realEstates.isEmpty
                    ? NoDataWidget(
                        title: 'No properties available',
                        imageWidget: EmptyStateWidget(),
                        retryText: 'Reload',
                        onRetry: () {
                          currentPage = 1;
                          realEstates.clear();
                          fetchRealEstates();
                        },
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: realEstates.length + 1,
                        itemBuilder: (context, index) {
                          if (index == realEstates.length) {
                            return isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(child: LoaderWidget()),
                                  )
                                : const SizedBox();
                          }
                          return RealEstateCard(
                              model: realEstates[index], savedIds: savedIds);
                        },
                      ),
            LoaderWidget()
                .visible(appStore.isLoading && realEstates.isNotEmpty),
          ],
        ),
      ),
    );
  }
}

class RealEstateCard extends StatefulWidget {
  final RealEstateModel model;
  final List<int> savedIds;

  const RealEstateCard(
      {super.key, required this.model, required this.savedIds});

  @override
  State<RealEstateCard> createState() => _RealEstateCardState();
}

class _RealEstateCardState extends State<RealEstateCard> {
  late PageController _pageController;
  int _currentPage = 0;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    isSaved = widget.savedIds.contains(widget.model.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        isSaved = message.toLowerCase().contains('saved');
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
    final model = widget.model;

    return Card(
      elevation: 0,
      color: appStore.isDarkMode ? cardDarkColor : cardLightColor,
      margin: EdgeInsets.only(bottom: width * 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.02)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: model.images.isNotEmpty
                    ? SizedBox(
                        height: height * 0.2,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: model.images.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            return Image.network(
                              model.images[index],
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
                        child: Icon(Icons.image, size: width * 0.2),
                      ),
              ),
              Positioned(
                top: width * 0.03,
                left: width * 0.03,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.02, vertical: width * 0.015),
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
                  child: Icon(Icons.share, size: width * 0.05),
                ),
              ),
              Positioned(
                bottom: width * 0.03,
                right: width * 0.03,
                child: GestureDetector(
                  onTap: () => saveOrUnsaveRealEstate(model.id!),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? primaryColor : Colors.black,
                      size: width * 0.06,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: width * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.title ?? '', style: boldTextStyle(size: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: width * 0.04, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(model.location ?? '',
                            style: secondaryTextStyle())),
                  ],
                ),
                SizedBox(height: height * 0.01),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${model.areaSqfeet} Sqft',
                          style: TextStyle(fontSize: width * 0.03),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      8.width,
                      Expanded(
                        child: Text(
                          model.propertyType ?? '',
                          style: TextStyle(fontSize: width * 0.03),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      8.width,
                      Expanded(
                        child: Text(
                          model.ownerName ?? '',
                          style: TextStyle(fontSize: width * 0.03),
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
          const Divider(height: 1),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: width * 0.032, vertical: width * 0.03),
            child: Row(
              children: [
                Text('₹${model.monthlyRent}', style: boldTextStyle(size: 16)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding:  EdgeInsets.symmetric(
                        vertical: width * 0.03, horizontal: width * 0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final phone = model.ownerPhn?.replaceAll(' ', '').trim();
                    if (phone != null && phone.isNotEmpty) {
                      final Uri url = Uri(scheme: 'tel', path: phone);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        toast('Could not open dialer');
                      }
                    } else {
                      toast('Phone number not available');
                    }
                  },
                  child: const Text('Contact Owner',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
