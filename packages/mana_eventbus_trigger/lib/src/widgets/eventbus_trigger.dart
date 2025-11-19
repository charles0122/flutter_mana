import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import '../eventbus_adapter.dart';
import '../eventbus_default_adapter.dart';

class EventbusTrigger extends StatefulWidget with I18nMixin {
  final String name;
  final EventBusAdapter? adapter;

  const EventbusTrigger({super.key, required this.name, this.adapter});

  @override
  State<EventbusTrigger> createState() => _EventbusTriggerState();
}

class _EventbusTriggerState extends State<EventbusTrigger> {
  String? _selectedEvent;
  List<String> _events = const [];
  int _selectedHistoryIndex = -1;
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _eventFilter = TextEditingController();
  String _eventQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshEvents();
    _eventFilter.addListener(() {
      setState(() {
        _eventQuery = _eventFilter.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _eventFilter.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _refreshEvents() {
    final adapter = widget.adapter;
    if (adapter == null) {
      setState(() => _events = const []);
      return;
    }
    setState(() => _events = adapter.events);
  }

  @override
  Widget build(BuildContext context) {
    final adapter = widget.adapter;
    EventBusDefaultAdapter? defaultAdapter;
    if (adapter is EventBusDefaultAdapter) {
      defaultAdapter = adapter;
    }
    final listeners =
        (_selectedEvent != null && adapter != null)
            ? adapter.listenersOf(_selectedEvent!)
            : const [];
    // ignore: unused_local_variable
    final lastFire =
        (_selectedEvent != null && adapter != null)
            ? adapter.lastFireOf(_selectedEvent!)
            : (null, null);
    final histories =
        (_selectedEvent != null && defaultAdapter != null)
            ? defaultAdapter.historyOf(_selectedEvent!)
            : const [];
    final canEdit = defaultAdapter?.canEdit(_selectedEvent ?? '') ?? false;

    final filteredEvents =
        _eventQuery.isEmpty
            ? _events
            : _events
                .where(
                  (e) => e.toLowerCase().contains(_eventQuery.toLowerCase()),
                )
                .toList();

    return ManaFloatingWindow(
      name: widget.name,
      content: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _eventFilter,
                    decoration: const InputDecoration(
                      hintText: 'Search events',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Events'),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _refreshEvents,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredEvents.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final e = filteredEvents[i];
                        final count = adapter?.listenersOf(e).length ?? 0;
                        final active = adapter?.activeListenersCountOf(e) ?? 0;
                        final fires = adapter?.fireCountOf(e) ?? 0;
                        final selected = e == _selectedEvent;
                        return ListTile(
                          title: Text(e),
                          subtitle: Text(
                            'listeners: $active/$count, fires: $fires',
                          ),
                          selected: selected,
                          onTap: () => setState(() => _selectedEvent = e),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_selectedEvent ?? 'Select an event'),
                      const Spacer(),
                      // if (lastFire.$1 != null && lastFire.$2 != null)
                      //   Flexible(
                      //     child: Padding(
                      //       padding: const EdgeInsets.only(right: 8),
                      //       child: Text(
                      //         'last: ${lastFire.$1} at ${lastFire.$2}',
                      //       ),
                      //     ),
                      //   ),
                      ElevatedButton(
                        onPressed:
                            (_selectedEvent != null &&
                                    defaultAdapter != null &&
                                    _selectedHistoryIndex >= 0)
                                ? () {
                                  defaultAdapter!.refireOriginal(
                                    _selectedEvent!,
                                    _selectedHistoryIndex,
                                  );
                                }
                                : null,
                        child: const Text('Fire'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Listeners'),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: listeners.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final l = listeners[i];
                                    return ListTile(
                                      title: Text(l.name ?? 'listener'),
                                      subtitle: Text(l.detail ?? ''),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('History'),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: histories.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final h = histories[i];
                                    final title = h.type;
                                    final subtitle =
                                        h.json != null
                                            ? h.json.toString()
                                            : h.event.toString();
                                    final selected = i == _selectedHistoryIndex;
                                    return ListTile(
                                      title: Text(title),
                                      subtitle: Text(subtitle),
                                      selected: selected,
                                      onTap: () {
                                        setState(
                                          () => _selectedHistoryIndex = i,
                                        );
                                        if (h.json != null) {
                                          _jsonController.text =
                                              h.json.toString();
                                        } else {
                                          _jsonController.clear();
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _jsonController,
                                maxLines: 6,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Edit JSON and Fire (requires serializer)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed:
                                    (defaultAdapter != null &&
                                            canEdit &&
                                            _selectedEvent != null)
                                        ? () {
                                          defaultAdapter!.refireJson(
                                            _selectedEvent!,
                                            _jsonController.text,
                                          );
                                        }
                                        : null,
                                child: const Text('Edit & Fire'),
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
