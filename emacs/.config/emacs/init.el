;;; From https://blog.aaronbieber.com/2015/05/24/from-vim-to-emacs-in-fourteen-days.html
(require 'package)

(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/"))
;; (add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/"))

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;;; From https://systemcrafters.net/emacs-from-scratch/the-best-default-settings/
;; Move customization variables to a separate file and load it.
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)
;; Revert buffers when the underlying file has changed (as long as the buffer doesn't have unsaved changes).
(global-auto-revert-mode 1)
;; Also revert Dired and other buffers
(setq global-auto-revert-non-file-buffers t)

;;; From https://systemcrafters.net/emacs-from-scratch/basics-of-emacs-configuration/
;; Don't show the splash screen
(setq inhibit-startup-message t)
;; Turn off some unneeded UI elements
;(menu-bar-mode -1)  ; Leave this one on if you're a beginner!
;(tool-bar-mode -1)
;(scroll-bar-mode -1)
;; Display line numbers in every buffer
(global-display-line-numbers-mode 1)

;; Maybe use this: https://ianyepan.github.io/posts/setting-up-use-package/
;; https://menno.io/posts/use-package/

;;; Package configs

(use-package elec-pair
  :config
  ;; Balance brackets in a lightweight way
  (electric-pair-mode))
(use-package paren
  :init
  (setq show-paren-delay 0)
  :config
  ;; Why isn't this on by default?
  (show-paren-mode))

(use-package modus-themes
  :ensure t
  :init
  ;; Add all your customizations prior to loading the themes
  (setq modus-themes-italic-constructs t
	;; Bold looks too strong.
        modus-themes-bold-constructs nil
        modus-themes-region '(accented bg-only no-extend))
  ;; Load the theme files before enabling a theme
  (modus-themes-load-themes)
  :config
  ;; Load the theme of your choice:
  (modus-themes-load-operandi) ;; OR (modus-themes-load-vivendi)
  :bind ("<f5>" . modus-themes-toggle))

(use-package ibuffer
  :bind ("C-x C-b" . ibuffer))

(use-package imenu
  :config
  (setq imenu-auto-rescan t)
  :bind ("H-i" . imenu))

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

;; Just show me what I can do with a prefix key!
(use-package which-key
  :ensure t
  :init
  (which-key-setup-side-window-right)
  (which-key-mode 1))
