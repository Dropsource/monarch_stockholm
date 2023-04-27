import 'package:flutter/material.dart';
import 'package:stockholm/stockholm.dart';

const _headerHeight = 24.0;
const _horizontalRowPadding = 8.0;

class StockholmTable extends StatefulWidget {
  const StockholmTable({
    required this.headerBuilder,
    required this.rowBuilder,
    required this.rowCount,
    required this.columnCount,
    required this.columnWidths,
    this.columnMinWidths,
    this.columnMaxWidths,
    this.defaultMinColumnWidth = 50,
    this.defaultMaxColumnWidth = 200,
    this.backgroundColor,
    this.altBackgroundColor,
    this.headerDecoration,
    this.selectedRow,
    this.selectableRows = true,
    this.onSelectedRow,
    this.cellHeight = 24.0,
    this.shrinkWrap = false,
    this.physics,
    this.drawGrid = true,
    Key? key,
  }) : super(key: key);

  final List<Widget> Function(BuildContext context) headerBuilder;
  final List<Widget> Function(BuildContext context, int row, bool selected)
      rowBuilder;
  final List<double> columnWidths;
  final List<double>? columnMinWidths;
  final List<double>? columnMaxWidths;
  final double defaultMinColumnWidth;
  final double defaultMaxColumnWidth;
  final int rowCount;
  final int columnCount;
  final Color? backgroundColor;
  final Color? altBackgroundColor;
  final BoxDecoration? headerDecoration;
  final int? selectedRow;
  final bool selectableRows;
  final ValueChanged<int?>? onSelectedRow;
  final double cellHeight;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final bool drawGrid;

  @override
  _StockholmTableState createState() => _StockholmTableState();
}

class _StockholmTableState extends State<StockholmTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  int? _selectedRow;
  double get _totalColumnWidths => _widths.fold(0, (prev, e) => prev + e);

  final _widths = <double>[];

  @override
  void initState() {
    super.initState();
    _selectedRow = widget.selectedRow;
    for (var width in widget.columnWidths) {
      _widths.add(width);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var themeAltColor = Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.045)
        : Colors.white12;
    var altBgColor = widget.altBackgroundColor ?? themeAltColor;

    var isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return LayoutBuilder(builder: (context, constraints) {
      double _totalColumnSpace =
          constraints.maxWidth - _horizontalRowPadding * 2;
      bool hasHorizontalOverflow = _totalColumnWidths > _totalColumnSpace;

      double extraSpace = 0;
      if (!hasHorizontalOverflow) {
        extraSpace = _totalColumnSpace - _totalColumnWidths;
      }

      Widget innerListView;

      if (widget.shrinkWrap) {
        var children = <Widget>[];
        for (int i = 0; i < widget.rowCount; i++) {
          children.add(_TableRow(
            cells: widget.rowBuilder(context, i, _selectedRow == i),
            widths: _widths,
            height: widget.cellHeight,
            selected: _selectedRow == i,
            backgroundColor: i % 2 == 1 ? altBgColor : null,
            hasHorizontalOverflow: hasHorizontalOverflow,
            grid: widget.drawGrid,
            extraSpace: extraSpace,
            onPressed: () {
              if (widget.selectableRows) {
                setState(() {
                  _selectedRow = i;
                });
                if (widget.onSelectedRow != null) {
                  widget.onSelectedRow!(i);
                }
              }
            },
          ));
        }

        innerListView = Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      } else {
        innerListView = ListView.builder(
          padding: EdgeInsets.symmetric(
            vertical: isWindows || widget.drawGrid ? 0 : 6,
          ),
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          itemCount: widget.rowCount,
          controller: _verticalController,
          prototypeItem: SizedBox(
            width: hasHorizontalOverflow
                ? _totalColumnWidths + _horizontalRowPadding * 2
                : constraints.maxWidth,
            height: widget.cellHeight,
          ),
          itemBuilder: (context, row) {
            var backgroundColor = row % 2 == 1 ? altBgColor : null;
            return _TableRow(
              cells: widget.rowBuilder(context, row, false),
              widths: _widths,
              height: widget.cellHeight,
              selected: _selectedRow == row,
              backgroundColor:
                  isWindows || widget.drawGrid ? null : backgroundColor,
              hasHorizontalOverflow: hasHorizontalOverflow,
              grid: widget.drawGrid,
              extraSpace: extraSpace,
              onPressed: () {
                if (widget.selectableRows) {
                  setState(() {
                    _selectedRow = row;
                  });
                  if (widget.onSelectedRow != null) {
                    widget.onSelectedRow!(row);
                  }
                }
              },
            );
          },
        );
      }

      return Scrollbar(
        controller: _horizontalController,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: hasHorizontalOverflow
                ? _totalColumnWidths + _horizontalRowPadding * 2
                : constraints.maxWidth,
            child: Column(
              children: [
                _TableHeader(
                  widths: _widths,
                  decoration: widget.headerDecoration,
                  cells: widget.headerBuilder(context),
                  grid: widget.drawGrid,
                  extraSpace: extraSpace,
                  onStartResizeColumn: _onStartResizeColumn,
                  onEndResizeColumn: _onEndResizeColumn,
                  onResizedColumn: _onResizedColumn,
                ),
                if (!widget.shrinkWrap)
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: !hasHorizontalOverflow,
                      ),
                      child: innerListView,
                    ),
                  ),
                if (widget.shrinkWrap) innerListView,
              ],
            ),
          ),
        ),
      );
    });
  }

  double _startColumnWidth = 0;

  void _onStartResizeColumn(int column) {
    _startColumnWidth = _widths[column];
  }

  void _onEndResizeColumn(int column) {
    // TODO: implement
  }

  void _onResizedColumn(int column, double delta) {
    var minWidth = widget.columnMinWidths?.elementAt(column) ??
        widget.defaultMinColumnWidth;
    var maxWidth = widget.columnMaxWidths?.elementAt(column) ??
        widget.defaultMaxColumnWidth;

    setState(() {
      var width = _startColumnWidth + delta;
      if (width < minWidth) {
        width = minWidth;
      } else if (width > maxWidth) {
        width = maxWidth;
      }
      _widths[column] = width;
    });
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.cells,
    required this.widths,
    required this.decoration,
    required this.grid,
    required this.extraSpace,
    required this.onResizedColumn,
    required this.onStartResizeColumn,
    required this.onEndResizeColumn,
    Key? key,
  }) : super(key: key);

  final List<Widget> cells;
  final List<double> widths;
  final BoxDecoration? decoration;
  final bool grid;
  final double extraSpace;
  final void Function(int column, double delta) onResizedColumn;
  final void Function(int column) onStartResizeColumn;
  final void Function(int column) onEndResizeColumn;

  @override
  Widget build(BuildContext context) {
    var cellWidgets = <Widget>[];
    int i = 0;
    for (var cell in cells) {
      var index = i;
      var width = widths[i];
      if (i == 0) {
        width -= _TableColumnResizeHandle._width / 2;
      } else {
        width -= _TableColumnResizeHandle._width;
      }

      cellWidgets.add(
        SizedBox(
          width: width,
          child: DefaultTextStyle(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall!,
            child: cell,
          ),
        ),
      );
      cellWidgets.add(
        _TableColumnResizeHandle(
          last: i == cells.length - 1,
          onDragStart: () {
            onStartResizeColumn(index);
          },
          onDragEnd: () {
            onEndResizeColumn(index);
          },
          onDragUpdate: (delta) {
            onResizedColumn(index, delta);
          },
        ),
      );

      i += 1;
    }

    return Container(
      decoration: decoration ??
          BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
            ),
            color: Theme.of(context).colorScheme.background,
          ),
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalRowPadding),
      child: Row(
        children: cellWidgets,
      ),
    );
  }
}

class _TableColumnResizeHandle extends StatefulWidget {
  const _TableColumnResizeHandle({
    required this.onDragUpdate,
    required this.onDragStart,
    required this.onDragEnd,
    required this.last,
    Key? key,
  }) : super(key: key);

  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;
  final bool last;

  static const _width = 8.0;

  @override
  _TableColumnResizeHandleState createState() =>
      _TableColumnResizeHandleState();
}

class _TableColumnResizeHandleState extends State<_TableColumnResizeHandle> {
  double _downX = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        _downX = details.globalPosition.dx;
        widget.onDragStart();
      },
      onHorizontalDragEnd: (details) {
        widget.onDragEnd();
      },
      onHorizontalDragUpdate: (details) {
        var globalDelta = details.globalPosition.dx - _downX;
        widget.onDragUpdate(globalDelta);
      },
      child: SizedBox(
        width: widget.last
            ? _TableColumnResizeHandle._width / 2
            : _TableColumnResizeHandle._width,
        child: Container(
          margin: const EdgeInsets.only(
              left: _TableColumnResizeHandle._width / 2 - 1),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.cells,
    required this.onPressed,
    required this.selected,
    required this.hasHorizontalOverflow,
    required this.widths,
    required this.height,
    required this.grid,
    required this.extraSpace,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  final List<Widget> cells;
  final VoidCallback onPressed;
  final bool selected;
  final bool hasHorizontalOverflow;
  final Color? backgroundColor;
  final List<double> widths;
  final double height;
  final bool grid;
  final double extraSpace;

  @override
  Widget build(BuildContext context) {
    var isWindows = Theme.of(context).platform == TargetPlatform.windows;

    var cellWidgets = <Widget>[];
    int i = 0;
    for (var cell in cells) {
      cellWidgets.add(
        Container(
          decoration: grid
              ? BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1.0,
                    ),
                  ),
                )
              : null,
          width: widths[i],
          height: height,
          child: DefaultTextStyle(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: selected ? Colors.white : null,
                ),
            child: cell,
          ),
        ),
      );
      i += 1;
    }

    if (extraSpace > 0) {
      cellWidgets.add(
        SizedBox(
          width: extraSpace,
          height: height,
        ),
      );
    }

    Widget contents;

    if (isWindows || grid) {
      contents = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontalRowPadding,
        ),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).primaryColor : backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: cellWidgets,
        ),
      );
    } else {
      contents = Container(
        margin: EdgeInsets.symmetric(
          horizontal: hasHorizontalOverflow ? 0.0 : _horizontalRowPadding,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: hasHorizontalOverflow ? _horizontalRowPadding : 0.0,
        ),
        decoration: BoxDecoration(
          borderRadius: hasHorizontalOverflow
              ? null
              : const BorderRadius.all(Radius.circular(4)),
          color: selected ? Theme.of(context).primaryColor : backgroundColor,
        ),
        child: Row(
          children: cellWidgets,
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: contents,
    );
  }
}

class StockholmTableCell extends StatelessWidget {
  const StockholmTableCell({
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    this.plainIconTheme,
    this.selectedIconTheme,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final Alignment alignment;
  final EdgeInsets padding;
  final IconThemeData? plainIconTheme;
  final IconThemeData? selectedIconTheme;

  @override
  Widget build(BuildContext context) {
    var tableRow = context.findAncestorWidgetOfExactType<_TableRow>();
    assert(
      tableRow != null,
      'Table cell needs to be a child of StockholmTable',
    );

    IconThemeData iconTheme;
    if (tableRow!.selected) {
      iconTheme = selectedIconTheme ??
          const IconThemeData(
            color: Colors.white,
          );
    } else {
      iconTheme = plainIconTheme ??
          IconThemeData(
            color: StockholmColors.fromContext(context).gray.contrast,
          );
    }

    return Container(
      alignment: alignment,
      padding: padding,
      child: IconTheme(
        data: iconTheme,
        child: child,
      ),
    );
  }
}

class StockholmTableHeaderCell extends StatelessWidget {
  const StockholmTableHeaderCell({
    required this.child,
    this.alignment = Alignment.centerLeft,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
    Key? key,
  }) : super(key: key);

  final Widget child;
  final Alignment alignment;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: padding,
      child: child,
    );
  }
}
