import 'package:flutter/material.dart';
import 'package:interstellar/src/api/content_sources.dart';
import 'package:interstellar/src/api/magazines.dart' as api_magazines;
import 'package:interstellar/src/screens/entries/entries_screen.dart';
import 'package:interstellar/src/screens/explore/magazine_screen.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MagazinesScreen extends StatefulWidget {
  const MagazinesScreen({
    super.key,
  });

  @override
  State<MagazinesScreen> createState() => _MagazinesScreenState();
}

class _MagazinesScreenState extends State<MagazinesScreen> {
  api_magazines.MagazinesSort sort = api_magazines.MagazinesSort.hot;
  String search = "";

  final PagingController<int, api_magazines.DetailedMagazine>
      _pagingController = PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage = await api_magazines.fetchMagazines(
          context.read<SettingsController>().instanceHost,
          page: pageKey,
          sort: sort,
          search: search.isEmpty ? null : search);

      final isLastPage =
          newPage.pagination.currentPage == newPage.pagination.maxPage;

      if (isLastPage) {
        _pagingController.appendLastPage(newPage.items);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newPage.items, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(
        () => _pagingController.refresh(),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  DropdownButton<api_magazines.MagazinesSort>(
                    value: sort,
                    onChanged: (newSort) {
                      if (newSort != null) {
                        setState(() {
                          sort = newSort;
                          _pagingController.refresh();
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: api_magazines.MagazinesSort.hot,
                        child: Text('Hot'),
                      ),
                      DropdownMenuItem(
                        value: api_magazines.MagazinesSort.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem(
                        value: api_magazines.MagazinesSort.newest,
                        child: Text('Newest'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 128,
                    child: TextFormField(
                      initialValue: search,
                      onChanged: (newSearch) {
                        setState(() {
                          search = newSearch;
                          _pagingController.refresh();
                        });
                      },
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(), label: Text('Search')),
                    ),
                  )
                ],
              ),
            ),
          ),
          PagedSliverList<int, api_magazines.DetailedMagazine>(
            pagingController: _pagingController,
            builderDelegate:
                PagedChildBuilderDelegate<api_magazines.DetailedMagazine>(
              itemBuilder: (context, item, index) => InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MagazineScreen(item.magazineId, data: item),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(children: [
                    if (item.icon?.storageUrl != null)
                      Image.network(
                        item.icon!.storageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    Container(
                        width: 8 + (item.icon?.storageUrl != null ? 0 : 32)),
                    Expanded(
                        child:
                            Text(item.name, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.feed),
                    Container(
                      width: 4,
                    ),
                    Text(intFormat(item.entryCount)),
                    const SizedBox(width: 12),
                    const Icon(Icons.comment),
                    Container(
                      width: 4,
                    ),
                    Text(intFormat(item.entryCommentCount)),
                    const SizedBox(width: 12),
                    OutlinedButton(
                        onPressed: () {},
                        child: Row(
                          children: [
                            const Icon(Icons.group),
                            Text(' ${intFormat(item.subscriptionsCount)}'),
                          ],
                        ))
                  ]),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}