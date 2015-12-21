(in-package :las)

(setf binary-types:*endian* :little-endian)

(define-binary-string 32-char-string 32)
(define-unsigned float64 8)

(define-binary-struct number-of-points-by-return ()
  (npbr-0 0 :binary-type u32)
  (npbr-1 0 :binary-type u32)
  (npbr-2 0 :binary-type u32)
  (npbr-3 0 :binary-type u32)
  (npbr-4 0 :binary-type u32))

(defun number-of-points-by-return (header)
  (with-slots (number-of-points-by-return) header
    (mapcar #'(lambda (slot-name)
                (slot-value number-of-points-by-return slot-name))
            (binary-record-slot-names 'number-of-points-by-return))))

(define-binary-struct project-id-4 ()
  (pid4-0 0 :binary-type u8)
  (pid4-1 0 :binary-type u8)
  (pid4-2 0 :binary-type u8)
  (pid4-3 0 :binary-type u8)
  (pid4-4 0 :binary-type u8)
  (pid4-5 0 :binary-type u8)
  (pid4-6 0 :binary-type u8)
  (pid4-7 0 :binary-type u8))

(defun project-id-4 (header)
  (with-slots (project-id-4) header
    (mapcar #'(lambda (slot-name)
                (slot-value project-id-4 slot-name))
            (binary-record-slot-names 'project-id-4))))

(define-binary-class public-header ()
  ((file-signature :binary-type (define-binary-string file-signature 4) :initform "LASF")
   (file-source-id :binary-type u16 :initform 0)
   (global-encoding :binary-type (define-bitfield global-encoding (u16)
                                   (((:bits)
                                     gps-time 0
                                     internal-wave-data 1
                                     external-wave-data 2
                                     synthetic-return-point 3)))
                    :initform '())
   (project-id-1 :binary-type u32 :initform 0)
   (project-id-2 :binary-type u16 :initform 0)
   (project-id-3 :binary-type u16 :initform 0)
   (project-id-4 :binary-type project-id-4
                 :initform (make-project-id-4))
   (version-major :binary-type u8 :initform 0)
   (version-minor :binary-type u8 :initform 0)
   (system-identifier :binary-type 32-char-string :initform "")
   (generating-software :binary-type 32-char-string :initform "")
   (file-creation-doy :binary-type u16 :initform 0)
   (file-creation-year :binary-type u16 :initform 0)
   (header-size :binary-type u16 :initform 0)
   (offset-to-point-data :binary-type u32 :initform 0)
   (number-of-variable-length-records :binary-type u32 :initform 0)
   (point-data-format-id :binary-type u8 :initform 0)
   (point-data-record-length :binary-type u16 :initform 0)
   (number-of-point-records :binary-type u32 :initform 0)
   (number-of-points-by-return :binary-type number-of-points-by-return
                              :initform (make-number-of-points-by-return))
   (x-scale :binary-type float64 :initform 0 :accessor x-scale)
   (y-scale :binary-type float64 :initform 0 :accessor y-scale)
   (z-scale :binary-type float64 :initform 0 :accessor z-scale)
   (x-offset :binary-type float64 :initform 0 :accessor x-offset)
   (y-offset :binary-type float64 :initform 0 :accessor y-offset)
   (z-offset :binary-type float64 :initform 0 :accessor z-offset)
   (max-x :binary-type float64 :initform 0 :accessor max-x)
   (min-x :binary-type float64 :initform 0 :accessor min-x)
   (max-y :binary-type float64 :initform 0 :accessor max-y)
   (min-y :binary-type float64 :initform 0 :accessor min-y)
   (max-z :binary-type float64 :initform 0 :accessor max-z)
   (min-z :binary-type float64 :initform 0 :accessor min-z)
   (start-of-waveform-data-packet :binary-type u64 :initform 0)))

(defmacro def-float64-accessor (name)
  (let ((header (gensym))
        (val (gensym)))
    `(progn
       (defmethod ,name ((,header public-header))
         (decode-float64 (slot-value ,header ',name)))
       (defmethod (setf ,name) (,val (,header public-header))
         (setf (slot-value ,header ',name) (encode-float64 ,val))))))

(def-float64-accessor x-scale)
(def-float64-accessor y-scale)
(def-float64-accessor z-scale)
(def-float64-accessor x-offset)
(def-float64-accessor y-offset)
(def-float64-accessor z-offset)
(def-float64-accessor max-x)
(def-float64-accessor max-y)
(def-float64-accessor max-z)
(def-float64-accessor min-x)
(def-float64-accessor min-y)
(def-float64-accessor min-z)

(defun scaled-min-max-z (header)
  (with-accessors ((min min-z)
                   (max max-z)
                   (zscale z-scale)
                   (zoff z-offset)) header
    (values (+ zoff (* zscale min))
            (+ zoff (* zscale max)))))

(define-binary-class variable-length-record ()
  ((reserved :binary-type u16 :initform 0)
   (user-id :binary-type (define-binary-string user-id 16) :initform "")
   (record-id :binary-type u16 :initform 0)
   (record-length-after-header :binary-type u16 :initform 0)
   (description :binary-type 32-char-string :initform "")))

(defun read-headers (filename)
  (with-open-file (fd filename :element-type '(unsigned-byte 8))
    (read-binary 'public-header fd)))
