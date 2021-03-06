;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;             Geometry Algorithm                               ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :caad4lisp)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; autolisp  build in geometry utility function 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; (angle pt1 pt2)
;; Returns an angle in radians of a line defined by two endpoints
;; (distance pt1 pt2)
;; Returns the 3D distance between two points
;; (inters pt1 pt2 pt3 pt4 [onseg])
;; Finds the intersection of two lines
;; (osnap pt mode)
;; Returns a 3D point that is the result of applying an
;; Object Snap mode to a specified point
;; (polar pt ang dist)
;; Returns the UCS 3D point at a specified angle
;; and distance from a point

(defun Geom-X (thePoint)
  "Reads 1st element of a point."
  (car thePoint)
  )
(defun Geom-Y (thePoint)
  "Reads 2nd element of a point."
  (cadr thePoint)
  )
(defun Geom-Z (thePoint)
  "Reads 3rd element of a point."
  (caddr thePoint)
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; geometry entity making
;;;;;;;;;;;;;;;;;;;;;;;;;;

;; make lineStruct  
(defun Geom-Line-MakeStruct(entLineOrEdata / edata dataByKey )
  "return: (list entLine edata (list startPoint endPoint))"
  (if (listp entLineOrEdata)
      (setq edata entLineOrEdata )
      (setq edata (entget entLineOrEdata))
      )
  (setq dataByKey (Util-Data-GetDataByKey '(-1 10 11) edata ))
  (list (car dataByKey) (cdr dataByKey) edata)
  )

(defun Geom-Line-Flip(entLineOrEdata / lineStruct edata pointsData )
  "flip a line"
  (setq lineStruct (Geom-Line-MakeStruct entLineOrEdata))
  (setq edata (caddr lineStruct))
  (setq pointsData (cadr lineStruct ))
  (setq edata (subst (cons 10 (cadr pointsData)) (assoc 10 edata) edata ))
  (setq edata (subst (cons 11 (car  pointsData)) (assoc 11 edata) edata ))  
  (entmod edata)
  )

;; isClosed: 0 or 1  , 1=closed
(defun Geom-EntmakexPolyline (pointList isClosed )
  "entmakex: make pline by points"
  (entmakex 
   (append
    (list '(0 . "LWPOLYLINE")
          '(100 . "AcDbEntity") '(100 . "AcDbPolyline")
          (cons 90 (length pointList)) 
          (cons 70 isClosed)
	      ) ;_  list
    (mapcar '(lambda (x) (cons 10 x)) pointList)
    ) ;_  append
   ))

;;  function: entmake lines
(defun Geom-EntmakeLines ( pointList / segmentList )
  "entmake: make line segments by points"
  (setq segmentList (mapcar
                     '(lambda (p0 p1)
                       (cons p0 (list p1))
                       )
                     (reverse (cdr (reverse pointList)))
                     (cdr pointList)
                     )
        )
  (mapcar '(lambda(segment)
            (entmake (list
                      (cons  0 "LINE")
                      (cons 10 (car segment)) ; segmentPoint0
                      (cons 11 (cadr segment)) ; segmentPoint1
                      )
             )
            )
          segmentList )
  ) ;_ defun
 

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Geometric algorithm
;;;;;;;;;;;;;;;;;;;;;;;;


;; cn: 求pt0到通过pt1及pt2的垂直点
(defun Geom-PerpPoint (pt0 pt1 pt2)
    (inters pt1 pt2 pt0 (polar pt0 (+ (angle pt1 pt2) (/ pi 2) ) 1.0) nil)
)

;; line: (point0 point1)
;; param:  0-> startpoint 1-> endpoint
(defun Geom-Line-GetPointAtParam (line param / p0 p1 )
  "get a point at parament from a line"
  (Util-working)
  (setq p0 (car  line))
   (setq p1 (cadr line))
   (list (+ (* (- 1 param) (car p0))
            (* param (car p1))
            )
         
         (+ (* (- 1 param) (cadr p0))
            (*  param (cadr p1)))
         
         (+ (* (- 1 param) (caddr p0))
            (*  param (caddr p1)))  
         )
  )


;; todo: test
;; return: parament or nil
(defun Geom-Line-IsPointOnLine(line point / dx dy dz x y z  p0 p1)
  "check a point on a line or not."
  (setq p0 (car line))
  (setq p1 (cadr line))

  (setq dx (- (car   point) (car   p0)))
  (setq dy (- (cadr  point) (cadr  p0)))
  (setq dz (- (caddr point) (caddr p0)))

  (setq  x (- (car   p1) (car   p0)))
  (setq  y (- (cadr  p1) (cadr  p1)))
  (setq  z (- (caddr p1) (caddr p1)))

  (if (and  (= (/ dx x) (/ dy y))
            (= (/ dx x) (/ dz z))
            )
      (/ dx x)
      nil
      )
  )

;; todo: test
;; checkPoint: check point on line 0->not check, 1->check
(defun Geom-Line-GetParamAtPoint(line point checkPoint / p0 p1 )
  "get a parameter from a point on a line. 0->startpoint 1->endpoint"
  (if (= checkpoint 1)
      (Geom-Line-IsPointOnLine line point)
      )
  (setq p0 (car line))
  (setq p1 (cadr line))
  (/ (- (car point) (car p0))
     (- (car p1) (car p0))
     )
  )
  
;; todo: test
;; linex: (point0 point1)
;; param0: parameter at line0
;; param1: parameter at line1
(defun Geom-Line-GetParamAtIntersection(line0 line1 / l0p0 l0p1 l1p0 l1p1
                                        intersPoint )
  "get a point parameter from a line intersect with another line. 0->startpoint 1->endpoint"
  (setq l0p0 (car   line0))
  (setq l0p1 (cadr  line0))
  (setq l1p0 (car   line1))
  (setq l1p1 (cadr  line1))
  (setq intersPoint (inters l0p0 l0p1 l1p0 l1p1 nil))
  (list
   (Geom-Line-GetParamAtPoint line0 intersPoint)
   (Geom-Line-GetParamAtPoint line1 intersPoint)
   )
  )

;; todo: test
;; parameter:
;; line: (list p0 p1)
;; return: The angle is measured from the X axis of the current
;; construction plane, in radians, with angles increasing in
;; the counterclockwise direction. If 3D points are supplied,
;; they are projected onto the current construction plane.
(defun Geom-Line-GetLineAngle(line / p0 p1)
  "get a angle from a line"
  (setq p0 (car   line))
  (setq p1 (cadr  line))
  (angle p0 p1)
  )


;;;;;;;;;;;;;;;;;;
;;; Geom2D                              
;;;;;;;;;;;;;;;;;;

;; autolisp 内置 (angle pt1 pt2)
;; %i: (angle '(1.0 1.0) '(1.0 4.0))
;; %o: 1.5708
;; %i: (angle '(5.0 1.33) '(2.4 1.33))
;; %o: 3.14159
;; %i: (angle '(0 0) '(0 1))
;; %o: 1.57079633
;; %i: (angle '(0 1) '(0 0))
;; %o: 4.71238898
;;
;; 算斜度  pt1(x1 y1) pt2(x2 y2)   |(y1-y2)/(x1-x2)|
(defun Geom2D-GetSlope (pt1 pt2 / x)
    ; Vertical?
    (if (equal (setq x (abs (- (car pt1) (car pt2)))) 0.0 Util-Math-Fuzz)
        ; Yes, return NIL
        nil
        ; No, compute slope
        ; Converts a number into a string
        ; (rtos number [mode [precision]])
        (rtos (/ (abs (- (cadr pt1) (cadr pt2))) x) 2 4)
    )
)

(princ "geom.lisp loaded")
(princ)
