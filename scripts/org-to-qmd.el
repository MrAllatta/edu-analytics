;;; org-to-qmd.el --- Export Org files to Quarto Markdown -*- lexical-binding: t -*-
;;
;;; Commentary:
;;
;; Usage: emacs --batch -l scripts/org-to-qmd.el
;; Or from Emacs: M-x load-file RET scripts/org-to-qmd.el RET
;;                M-x org-export-all-to-qmd
;;
;;; Code:

(require 'org)
(require 'ox-md)

(defvar org-qmd-src-dir "org/"
  "Directory containing org source files.")

(defvar org-qmd-out-dir "output/"
  "Directory for output qmd files.")

(defun org-export-to-qmd (org-file)
  "Export ORG-FILE to Quarto markdown (.qmd)."
  (let* ((base-name (file-name-base org-file))
         (md-file (concat (file-name-directory org-file) base-name ".md"))
         (qmd-file (concat org-qmd-out-dir base-name ".qmd")))
    
    (message "Exporting: %s" org-file)
    
    ;; Open and export
    (with-current-buffer (find-file-noselect org-file)
      (org-md-export-to-markdown)
      (kill-buffer))
    
    ;; Rename to .qmd
    (when (file-exists-p md-file)
      (rename-file md-file qmd-file t)
      (message "  -> %s" qmd-file))))

(defun org-export-all-to-qmd ()
  "Export all org files in `org-qmd-src-dir` to qmd."
  (interactive)
  (let ((org-files (directory-files org-qmd-src-dir t "\\.org$")))
    (dolist (file org-files)
      (org-export-to-qmd file))
    (message "Exported %d files." (length org-files))))

;; Auto-run in batch mode
(when noninteractive
  (org-export-all-to-qmd))

(provide 'org-to-qmd)
;;; org-to-qmd.el ends here
