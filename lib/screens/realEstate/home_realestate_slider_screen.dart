import 'dart:convert';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/get_all_realestate.dart';
import '../../network/network_utils.dart';
import '../../utils/colors.dart';
import '../../utils/configs.dart';

class RealEstateHomeSlider extends StatefulWidget {
  const RealEstateHomeSlider({super.key});

  @override
  State<RealEstateHomeSlider> createState() => _RealEstateHomeSliderState();
}

class _RealEstateHomeSliderState extends State<RealEstateHomeSlider> {
  List<RealEstateModel> realEstates = [];
  List<int> savedIds = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchSavedIds();
    fetchRealEstates();
  }

  Future<void> fetchSavedIds() async {
    try {
      final savedRes = await http.get(
        Uri.parse('${BASE_URL}get-saved-realestate/${appStore.userId}'),
        headers: buildHeaderTokens(),
      );

      if (savedRes.statusCode == 200) {
        final List savedData = jsonDecode(savedRes.body)['data'];
        setState(() {
          savedIds = savedData.map((e) => e['id'] as int).toList();
        });
      }
    } catch (e) {
      log('Saved ID fetch error: $e');
    }
  }

  Future<void> fetchRealEstates() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${BASE_URL}get-all-realestate?page=1'),
        headers: buildHeaderTokens(),
      );

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        final List data = jsonData['data'];

        setState(() {
          realEstates =
              data.map((e) => RealEstateModel.fromJson(e)).toList();
        });
      } else {
        toast('Failed to load data.');
      }
    } catch (e) {
      toast('Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleSave(int serviceId) async {
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
        toast(result['message']);
        await fetchSavedIds(); // Update saved icon state immediately
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
    double width = MediaQuery.of(context).size.width;
    double cardWidth = width * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Looking For', style: boldTextStyle(size: 14)).paddingLeft(15),
        12.height,
        SizedBox(
          height: width * 0.8,
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: realEstates.length,
                  itemBuilder: (context, index) {
                    final model = realEstates[index];
                    final isSaved = savedIds.contains(model.id);

                    return Container(
                      width: cardWidth,
                      margin: EdgeInsets.only(right: 12),
                      child: RealEstateMiniCard(
                        model: model,
                        isSaved: isSaved,
                        onSaveToggle: () async {
                          await toggleSave(model.id!);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class RealEstateMiniCard extends StatelessWidget {
  final RealEstateModel model;
  final bool isSaved;
  final VoidCallback onSaveToggle;

  const RealEstateMiniCard({
    super.key,
    required this.model,
    required this.isSaved,
    required this.onSaveToggle,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Card(
      elevation: 0,
      color: appStore.isDarkMode ? cardDarkColor : cardLightColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: model.images.isNotEmpty
                    ? Image.network(
                        model.images.first,
                        height: width * 0.3,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: width * 0.3,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.image, size: width * 0.2),
                      ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onSaveToggle,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: isSaved ? primaryColor : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(model.title ?? '',
                    style: boldTextStyle(size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                4.height,
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.grey.shade600),
                    4.width,
                    Expanded(
                      child: Text(
                        model.location ?? '',
                        style: secondaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                8.height,
                Text('${model.areaSqfeet} Sqft',
                    style: secondaryTextStyle(size: 12)),
                4.height,
                Text('₹${model.monthlyRent}',
                    style: boldTextStyle(size: 14, color: Colors.green)),
                8.height,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Contact',
                        style: boldTextStyle(size: 12, color: white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
