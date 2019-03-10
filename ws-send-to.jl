;;; ws-send-to.jl --- Workspace sending functions.
;; Copyright 1999,2000 by Dave Pearson <davep@davep.org>
;; $Revision: 1.9 $

;; ws-send-to.jl is free software distributed under the terms of the GNU
;; General Public Licence, version 2. For details see the file COPYING.

;;; Commentary:
;;
;; This sawfish <URL:http://sawmill.sourceforge.net/> module provides a
;; couple of functions that help modify the "Send window to" menu option in
;; the default `window-ops-menu' so that it offers a list of workspaces
;; alongside or instead of the usual next/previous options.
;;
;; To use this code simply drop it (or a compiled copy) into your load-path
;; and in your ~/.sawfishrc put:
;;
;; (require 'ws-send-to)
;;
;; After that you can control the actions of this code in the advanced
;; workspace section of the sawfish configuration manager.

;;; Thanks:
;;
;; Matt Kraai <kraai@ghs.com> for pointing out that the main function should
;; be added to `workspace-state-change-hook' to ensure that the menu is
;; always correct.

;;; Code:

;; Stuff we require.

(require 'menus)                        ; We need to ensure that
					; `window-ops-menu' is defined.

;; Customise options.

(defgroup send-to "Send window to menu" :group workspace)

(defcustom ws-send-to-enabled nil
  "Enable the explicit send-to menu?"
  :type      boolean
  :group     (workspace send-to)
  :after-set (lambda () (ws-send-to)))

(defcustom ws-send-to-action 'replace
  "How to add the explicit send-to menu."
  :type      symbol
  :options   (replace prepend append sub)
  :group     (workspace send-to)
  :after-set (lambda () (ws-send-to)))

(defcustom ws-send-to-menu-prompt (_ "_Send window to")
  "Text of the \"Send window to\" menu item."
  :type      string
  :group     (workspace send-to))

;; Non-customisable variables.

(defvar ws-send-to-original-menu nil
  "The original send-to menu.")
  
;; Main code.

(defun ws-send-to-build-menu ()
  "Build a send-to menu."
  (letrec ((build-menu (lambda (ws)
                         (unless (zerop ws)
                           (cons (list (or (nth (1- ws) workspace-names)
                                           (format nil (_ "Workspace %d") ws))
                                       `(send-window-to-workspace-from-first
                                         (current-event-window) ,(1- ws)))
                                 (build-menu (1- ws)))))))
    (reverse (build-menu (1+ (cdr (workspace-limits)))))))

(defun ws-send-to-set (thing)
  "Set the \"Send window to\" menu to THING."
  (let ((swt-menu (assoc ws-send-to-menu-prompt window-ops-menu)))
    (when swt-menu
      (setcdr swt-menu thing))))

(defun ws-send-to-replace-menu ()
  "Make the \"Send window to\" menu item more explicit.

Calling this function modifies the \"Send window to\" menu so that it is a
list of workspaces. Selecting a workspace from that list sends the window to
that workspace.

Don't forget to set `workspace-names' to get meaningful menu options."
  (ws-send-to-set (ws-send-to-build-menu)))

(defun ws-send-to-prepend-menu ()
  "Prepend the explicit send-to options to the send-to menu.

Calling this function modifies the \"Send window to\" menu so that it begins
with a list of workspaces. Selecting a workspace from that list sends the
window to that workspace.

Don't forget to set `workspace-names' to get meaningful menu options."
  (ws-send-to-set (append (ws-send-to-build-menu)
                          (list nil)
                          (cdr (copy-sequence ws-send-to-original-menu)))))

(defun ws-send-to-append-menu ()
  "Append the explicit send-to options to the send-to menu.

Calling this function modifies the \"Send window to\" menu so that it ends
with a list of workspaces. Selecting a workspace from that list sends the
window to that workspace.

Don't forget to set `workspace-names' to get meaningful menu options."
  (ws-send-to-set (append (cdr (copy-sequence ws-send-to-original-menu))
                          (list nil)
                          (ws-send-to-build-menu))))

(defun ws-send-to-sub-menu ()
  "Add the explicit send-to options as a sub-menu of the send-to menu.

Calling this function modifies the \"Send window to\" menu so that it
contains a sub-menu which is a list of workspaces. Selecting a workspace
from that list sends the window to that workspace.

Don't forget to set `workspace-names' to get meaningful menu options."
  (ws-send-to-set (append (cdr (copy-sequence ws-send-to-original-menu))
                          (list nil)
                          (list (cons (_ "Workspace") (ws-send-to-build-menu))))))

(defun ws-send-to-reset ()
  "Reset the \"Send window to\" menu to its original value."
  (when ws-send-to-original-menu
    (ws-send-to-set (cdr ws-send-to-original-menu))))

(defun ws-send-to ()
  (unless ws-send-to-original-menu
    (let ((st-menu (assoc ws-send-to-menu-prompt window-ops-menu)))
      (setq ws-send-to-original-menu (copy-sequence st-menu))))
  (if ws-send-to-enabled
      ((symbol-value (intern (format nil "ws-send-to-%s-menu" ws-send-to-action))))
    (ws-send-to-reset)))

;; Make sure the menu gets re-built if the workspace list changes.
(add-hook 'workspace-state-change-hook ws-send-to)

(provide 'ws-send-to)

;;; ws-send-to.el ends here
