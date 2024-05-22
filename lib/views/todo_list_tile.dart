import 'package:flutter/material.dart';
import 'package:flutter_app/models/todo_item.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TodoListTile extends StatefulWidget {
  final TodoItem item;
  final Function() onTap;
  final Function(BuildContext) onReassign, onDelete;

  const TodoListTile(
      {super.key,
      required this.item,
      required this.onTap,
      required this.onReassign,
      required this.onDelete});

  @override
  State<TodoListTile> createState() => _TodoListTileState();
}

class _TodoListTileState extends State<TodoListTile> {
  int _titleLineCount = 1;
  int _subtitleLineCount = 0;

  @override
  void initState() {
    super.initState();

    // During the build phase, the state `titleLineCount` and `subtitleLineCount` are changed without a call to `setState` (to avoid error). So, we add a post-frame callback to update UI (Specifically, the `ListTile.titleAlignment` prop) after the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.7,
        children: [
          SlidableAction(
            // flex: 2,
            onPressed: widget.onReassign,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: Icons.shortcut,
            label: 'Reassign',
          ),
          SlidableAction(
            onPressed: widget.onDelete,
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        // isThreeLine: viewModel.isThreeLine,
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        leading: SizedBox(
          height: double.infinity,
          child:
              Icon(widget.item.isDone ? Icons.task_alt : Icons.circle_outlined),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            String title = widget.item.name;
            TextStyle titleStyle =
                Theme.of(context).textTheme.titleMedium!.copyWith(
                      // color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: widget.item.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    );

            _titleLineCount = _measureTextLineCount(
              title,
              titleStyle,
              constraints.maxWidth,
            );

            return Text(title, style: titleStyle);
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            if (widget.item.details != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  String subtitle = widget.item.details!.trim();
                  TextStyle subtitleStyle =
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            decoration: widget.item.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          );

                  _subtitleLineCount = _measureTextLineCount(
                    subtitle,
                    subtitleStyle,
                    constraints.maxWidth,
                  );

                  return Text(subtitle, style: subtitleStyle);
                },
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(widget.item.category.title,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        )),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .color!
                      .withOpacity(0.5),
                )
              ],
            ),
          ],
        ),
        titleAlignment: _titleLineCount + _subtitleLineCount > 1
            ? ListTileTitleAlignment.top
            : ListTileTitleAlignment.center,
        onTap: widget.onTap,
      ),
    );
  }

  int _measureTextLineCount(String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );

    // Layout text under the width constraint
    textPainter.layout(maxWidth: maxWidth);

    return textPainter.computeLineMetrics().length;
  }
}
