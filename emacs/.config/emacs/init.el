;;; From https://blog.aaronbieber.com/2015/05/24/from-vim-to-emacs-in-fourteen-days.html
(require 'package)

(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/"))
(customize-set-variable 'package-archive-priorities '(("org" . 100)
				   ("gnu" . 50)
				   ("melpa-stable" . 25)
				   ("melpa" . 10)))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; Imenu entries for use-package in init!
;; Based on https://issuecloser.com/blog/make-imenu-recognize-usepackage-directives.
(defun my/setup-imenu-for-use-package ()
  "Recognize `use-package` in imenu"
  (when (and buffer-file-name		; In case the buffer's not backed by a file.
	     (string= (file-truename buffer-file-name) (file-truename user-init-file)))
    (add-to-list
     'imenu-generic-expression
     '("Packages" "^\\s-*(\\(use-package\\)\\s-+\\(\\(\\sw\\|\\s_\\)+\\)" 2))))
(add-hook 'emacs-lisp-mode-hook 'my/setup-imenu-for-use-package)

;;; From https://systemcrafters.net/emacs-from-scratch/the-best-default-settings/
;; Move customization variables to a separate file and load it.
(customize-set-variable 'custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)
;; Revert buffers when the underlying file has changed (as long as the buffer doesn't have unsaved changes).
(global-auto-revert-mode 1)
;; Also revert Dired and other buffers
(customize-set-variable 'global-auto-revert-non-file-buffers t)
;; Remember and restore the last cursor location of opened files
(save-place-mode 1)

;;; From https://systemcrafters.net/emacs-from-scratch/basics-of-emacs-configuration/
;; Don't show the splash screen
(customize-set-variable 'inhibit-startup-message t)
;; Turn off some unneeded UI elements
;(menu-bar-mode -1)  ; Leave this one on if you're a beginner!
(tool-bar-mode -1)
;(scroll-bar-mode -1)
;; Display line numbers in every buffer
(global-display-line-numbers-mode 1)
(dolist (mode '(;; pdf-tools doesn't work well with line numbers.  See https://pdftools.wiki/f178ba41
		pdf-view-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode -1))))
;; Display column in modeline.
(column-number-mode)
;; Much more focussed than Vim's `listchars' variable.  I often only
;; want to see trailing whitespace anyway.
(customize-set-variable 'show-trailing-whitespace t)
;; Human-readable file sizes in Dired.
(customize-set-variable 'dired-listing-switches "-alh")
(customize-set-variable 'dired-dwim-target t)

;; Maybe use this: https://ianyepan.github.io/posts/setting-up-use-package/
;; https://menno.io/posts/use-package/

;;; Package configs

(use-package elec-pair
  :config
  ;; Balance brackets in a lightweight way
  (electric-pair-mode))
(use-package paren
  :custom
  (show-paren-delay 0)
  :config
  ;; Why isn't this on by default?
  (show-paren-mode))

(use-package modus-themes
  :ensure t
  :custom
  (modus-themes-italic-constructs t)
  ;; Bold looks too strong.
  (modus-themes-bold-constructs nil)
  (modus-themes-region '(accented bg-only no-extend))
  :init
  ;; Load the theme files before enabling a theme
  (modus-themes-load-themes)
  :config
  ;; Load the theme of your choice:
  (modus-themes-load-operandi) ;; OR (modus-themes-load-vivendi)
  :bind ("<f5>" . modus-themes-toggle))

(use-package ibuffer
  :bind (("C-x C-b" . ibuffer)
	 :map ibuffer-mode-map
	 ;; I've accidentally printed before!
	 ("P" . (lambda ()
		  "Print marked buffers as with `print-buffer', with confirmation."
		  (interactive)
		  (if (yes-or-no-p "Print? ") (ibuffer-do-print))))))
(use-package dired
  :bind (:map dired-mode-map
	      ;; I've accidentally printed before!
	      ("P" . (lambda (&optional arg)
		       "Print the marked (or next ARG) files, with confirmation."
		       (interactive)
		       (if (yes-or-no-p "Print? ") (dired-do-print arg))))))

(use-package imenu
  :custom
  (imenu-auto-rescan t)
  :bind ("H-i" . imenu))
(use-package imenu-anywhere
  :ensure t
  :bind ("H-M-i" . imenu-anywhere))

(use-package simple
  :bind (("H-n H-n" . clone-buffer)
	 ("H-n n" . clone-indirect-buffer)))

(use-package help-mode
  :bind (:map help-mode-map
	      ("M-n" . forward-button)
	      ("M-p" . backward-button)))

(use-package info
  :bind (:map Info-mode-map
	      ("M-n" . Info-next-reference)
	      ("M-p" . Info-prev-reference)))

;; Completions

(use-package corfu
  :ensure t
  :init
  ;; Recommended: Enable Corfu globally.
  ;; This is recommended since Dabbrev can be used globally (M-/).
  ;; See also `corfu-excluded-modes'.
  (global-corfu-mode)
  ;; From README.
  :custom
  (corfu-cycle t) ;; Enable cycling for `corfu-next/previous'
  (corfu-auto t)  ;; Enable auto completion
  ;; (corfu-separator ?\s)          ;; Orderless field separator
  ;; (corfu-quit-at-boundary nil)   ;; Never quit at completion boundary
  ;; (corfu-quit-no-match nil)      ;; Never quit, even if there is no match
  ;; (corfu-preview-current nil)    ;; Disable current candidate preview
  ;; (corfu-preselect-first nil)    ;; Disable candidate preselection
  ;; (corfu-on-exact-match nil)     ;; Configure handling of exact matches
  ;; (corfu-echo-documentation nil) ;; Disable documentation in the echo area
  ;; (corfu-scroll-margin 5)        ;; Use scroll margin

  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))
  ;; Enable in any minibuffer as long as no other completion UI is active.  From README.
  :hook (minibuffer-setup . (lambda ()
			      "Enable Corfu in the minibuffer if Vertico is not active."
			      (unless (bound-and-true-p vertico--input)
				;; (setq-local corfu-auto nil) Enable/disable auto completion
				(corfu-mode 1)))))
(use-package corfu-doc
  :ensure t
  :after corfu
  :hook (corfu-mode . corfu-doc-mode)
  :bind (:map corfu-map
	      ("M-p". corfu-doc-scroll-down) ;; corfu-next
	      ("M-n" . corfu-doc-scroll-up) ;; corfu-previous
	      ("M-d" . corfu-doc-toggle)))

;; vertico, savehist, marginalia from https://systemcrafters.cc/emacs-tips/streamline-completions-with-vertico/
;; TODO: use https://cestlaz.github.io/post/using-emacs-80-vertico/
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t))

(use-package savehist
  :init
  (savehist-mode))

(use-package marginalia
  :ensure t
  :after vertico
  :init
  (marginalia-mode)
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil)))

;; Straight from README
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(customize-set-variable 'read-file-name-completion-ignore-case t)
(customize-set-variable 'read-buffer-completion-ignore-case t)

;; Just show me what I can do with a prefix key!
(use-package which-key
  :ensure t
  :init
  (which-key-setup-side-window-right)
  (which-key-mode 1))

(use-package pdf-tools
  :ensure t
  :custom
  (TeX-view-program-selection '((output-pdf "PDF Tools"))))
  :config
  (pdf-tools-install)
  ;; Autorevert might not work reliably with (La)TeX.  See https://pdftools.wiki/24b671c6
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
;; Straight from AUCTeX Info manual.
(use-package tex
  :ensure auctex
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  ;; Uncomment if I start using \include or \input a lot.  From Info manual.
  ;(TeX-master nil)
  )

;; Version Control stuff
(use-package diff-hl
  :ensure t
  :custom
  (diff-hl-show-staged-changes nil)
  :init
  (diff-hl-dired-mode)
  (diff-hl-flydiff-mode)
  (global-diff-hl-mode))
(use-package magit
  :ensure t
  :after diff-hl
  :config
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

;; Just use one key for these things.
(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))
(use-package whole-line-or-region
  :ensure t
  :init
  (whole-line-or-region-global-mode))

(use-package ace-window
  :ensure t
  :custom
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  ;; The default command bound to M-SPC (just-one-space) is pretty useless.
  :bind ("M-SPC" . ace-window))
(use-package tab-bar
  ;; Analogy with Isearch.
  :bind ("C-x t C-s" . tab-bar-select-tab-by-name))
(use-package emacs
  ;; Switch the current buffer to the next/previous one *based on the current window's history*.
  :bind (("H-l" . previous-buffer)
	 ("H-r" . next-buffer)))
