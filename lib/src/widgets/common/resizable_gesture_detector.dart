import 'package:croppy/src/src.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A GestureDetector that allows resizing an AABB crop rect from its corners
/// and sides.
class ResizableGestureDetector extends StatelessWidget {
  const ResizableGestureDetector({
    super.key,
    required this.controller,
    required this.child,
    required this.gesturePadding,
  });

  /// The [CroppableImageController] that is used to handle the gestures.
  final CroppableImageController controller;

  /// The child widget that is wrapped by this widget.
  final Widget child;

  /// The padding around the child that is used to detect gestures.
  final double gesturePadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned(
          left: gesturePadding,
          top: gesturePadding,
          right: gesturePadding,
          bottom: gesturePadding,
          child: child,
        ),

        // Corners
        Positioned(
          left: 0.0,
          top: 0.0,
          width: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toTopLeft,
          ),
        ),
        Positioned(
          right: 0.0,
          top: 0.0,
          width: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toTopRight,
          ),
        ),
        Positioned(
          left: 0.0,
          bottom: 0.0,
          width: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toBottomLeft,
          ),
        ),
        Positioned(
          right: 0.0,
          bottom: 0.0,
          width: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toBottomRight,
          ),
        ),

        // Sides
        Positioned(
          left: gesturePadding * 2,
          top: 0.0,
          right: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toTop,
          ),
        ),
        Positioned(
          left: gesturePadding * 2,
          bottom: 0.0,
          right: gesturePadding * 2,
          height: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toBottom,
          ),
        ),
        Positioned(
          left: 0.0,
          top: gesturePadding * 2,
          width: gesturePadding * 2,
          bottom: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toLeft,
          ),
        ),
        Positioned(
          right: 0.0,
          top: gesturePadding * 2,
          width: gesturePadding * 2,
          bottom: gesturePadding * 2,
          child: _ResizeGestureDetector(
            controller: controller,
            direction: ResizeDirection.toRight,
          ),
        ),
      ],
    );
  }
}

class _ResizeGestureDetector extends StatefulWidget {
  const _ResizeGestureDetector({
    required this.controller,
    required this.direction,
  });

  final CroppableImageController controller;
  final ResizeDirection direction;

  @override
  State<_ResizeGestureDetector> createState() => _ResizeGestureDetectorState();
}

class _ResizeGestureDetectorState extends State<_ResizeGestureDetector> {
  void _onPanStart(DragStartDetails details) {
    // print(
    //     'ResizeGestureDetector: onPanStart triggered with details: ${details.globalPosition}.');
    widget.controller.onResizeStart();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // print(
    // 'ResizeGestureDetector: onPanUpdate triggered with delta: ${details.delta}.');
    widget.controller.onResize(
      offsetDelta: -details.delta,
      direction: widget.direction,
    );
  }

  void _onPanEnd() {
    // print('ResizeGestureDetector: onPanEnd triggered.');
    widget.controller.onResizeEnd();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.controller.isTransformationEnabled(
      Transformation.resize,
    );

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        CustomPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
          () => CustomPanGestureRecognizer(
              dragStartBehavior:
                  DragStartBehavior.down), // Specify dragStartBehavior
          (CustomPanGestureRecognizer instance) {
            if (isEnabled) {
              instance.onPanStart = _onPanStart;
              instance.onPanUpdate = _onPanUpdate;
              instance.onPanEnd = _onPanEnd;
              instance.onPanCancel =
                  _onPanEnd; // Use the same callback for cancel
            } else {
              instance.onPanStart = null;
              instance.onPanUpdate = null;
              instance.onPanEnd = null;
              instance.onPanCancel = null;
            }
          },
        ),
      },
      child: const SizedBox.expand(),
    );
  }
}

class CustomPanGestureRecognizer extends OneSequenceGestureRecognizer {
  CustomPanGestureRecognizer({
    Object? debugOwner,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(debugOwner: debugOwner);

  final DragStartBehavior dragStartBehavior;

  Function(DragStartDetails)? onPanStart;
  Function(DragUpdateDetails)? onPanUpdate;
  Function()? onPanEnd;
  Function()? onPanCancel;

  Offset? initialPosition;
  Offset? lastPosition;

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    resolve(GestureDisposition.accepted);
    if (dragStartBehavior == DragStartBehavior.down) {
      onPanStart?.call(DragStartDetails(globalPosition: event.position));
      lastPosition = event.position; // Initialize last position
    } else {
      initialPosition = event.position;
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      if (dragStartBehavior == DragStartBehavior.start &&
          initialPosition != null) {
        onPanStart?.call(DragStartDetails(globalPosition: initialPosition!));
        lastPosition = initialPosition; // Initialize last position
        initialPosition = null;
      }

      // Calculate delta
      final delta = event.position - (lastPosition ?? event.position);
      lastPosition = event.position;

      // print('CustomPanGestureRecognizer: Calculated delta: $delta');
      onPanUpdate?.call(DragUpdateDetails(
        globalPosition: event.position,
        delta: delta,
      ));
    } else if (event is PointerDownEvent &&
        dragStartBehavior == DragStartBehavior.down) {
      onPanStart?.call(DragStartDetails(globalPosition: event.position));
      lastPosition = event.position; // Initialize last position
    } else if (event is PointerUpEvent) {
      onPanEnd?.call();
      stopTrackingPointer(event.pointer);
      lastPosition = null; // Reset
    } else if (event is PointerCancelEvent) {
      onPanCancel?.call();
      stopTrackingPointer(event.pointer);
      lastPosition = null; // Reset
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {
    // print('CustomPanGestureRecognizer: Stopped tracking pointer $pointer.');
  }
}
