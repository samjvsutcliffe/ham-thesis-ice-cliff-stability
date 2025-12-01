(sb-ext:restrict-compiler-policy 'speed 3 3)
(sb-ext:restrict-compiler-policy 'debug 0 0)
(sb-ext:restrict-compiler-policy 'safety 0 0)
(setf *block-compile-default* t)
(ql:quickload :local-time)
(ql:quickload :cl-mpm/examples/ice/cliff-stability)
(ql:quickload :parse-float)
(in-package :cl-mpm/examples/ice/cliff-stability)
(setf lparallel:*debug-tasks-p* nil)

(let ((threads (parse-integer (if (uiop:getenv "OMP_NUM_THREADS") (uiop:getenv "OMP_NUM_THREADS") "16"))))
  (setf lparallel:*kernel* (lparallel:make-kernel threads :name "custom-kernel"))
  (format t "Thread count ~D~%" threads))

(defparameter *ref* (parse-float:parse-float (if (uiop:getenv "REFINE") (uiop:getenv "REFINE") "1")))
(defparameter *height* (parse-float:parse-float (if (uiop:getenv "HEIGHT") (uiop:getenv "HEIGHT") "400")))
(defparameter *floatation* (parse-float:parse-float (if (uiop:getenv "FLOATATION") (uiop:getenv "FLOATATION") "0.9")))

(format t "Running~%")

(let ((stability-dir (merge-pathnames (format nil "./data-cliff-stability/"))))
  (ensure-directories-exist stability-dir)
  (defparameter *heights* heights)
  (defparameter *floatations* floatations)
  (let ((height *height*)
        (flotation *floatation*))
    (let ((res t))
      (let* ((mps 2)
             (output-dir (format nil "./output-~f-~f/" height flotation)))
        (format t "Outputting to ~A~%" output-dir)
        (format t "Problem ~f ~f~%" height flotation)
        (setup :refine 0.5d0
               :friction 0.5d0
               :bench-length 0d0
               :ice-height height
               :mps mps
               :cryo-static nil
               :aspect 1d0
               :slope 0d0
               :floatation-ratio flotation)
        (plot-domain)
        (setf (cl-mpm/buoyancy::bc-viscous-damping *water-bc*) 0d0)
        (setf (cl-mpm/damage::sim-enable-length-localisation *sim*) nil)
        (setf (cl-mpm/aggregate::sim-enable-aggregate *sim*) t
              ;; (cl-mpm::sim-ghost-factor *sim*) (* 1d9 1d-3)
              (cl-mpm::sim-ghost-factor *sim*) nil
              )
        (cl-mpm/setup::set-mass-filter *sim* 918d0 :proportion 1d-9)
        (let ((res (cl-mpm/dynamic-relaxation::run-quasi-time
                     *sim*
                     :output-dir output-dir
                     :dt 1d3
                     :total-time 1d6
                     ;; :steps 1000
                     :dt-scale 1d0
                     :conv-criteria 1d-3
                     :substeps 50
                     :enable-damage t
                     :enable-plastic t
                     :min-adaptive-steps -4
                     :max-adaptive-steps 6
                     :save-vtk-dr nil
                     :elastic-solver 'cl-mpm/dynamic-relaxation::mpm-sim-dr-ul
                     :plotter (lambda (sim) (plot-domain))
                     :post-conv-step (lambda (sim) (plot-domain)))))
          (format t "Stability:~E ~E ~A   ~%" height flotation res)
          (save-stabilty-data stability-dir *sim* res height flotation)
          )))))
