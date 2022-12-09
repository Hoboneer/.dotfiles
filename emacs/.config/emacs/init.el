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

(customize-set-variable 'use-package-enable-imenu-support t)
(eval-when-compile
  (require 'use-package))

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
(menu-bar-mode -1)
(tool-bar-mode -1)
;(scroll-bar-mode -1)
;; Display line numbers in every buffer
(global-display-line-numbers-mode 1)
(dolist (mode '(;; pdf-tools doesn't work well with line numbers.  See https://pdftools.wiki/f178ba41
		pdf-view-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode -1))))
;; Display column in modeline.
(column-number-mode)
(size-indication-mode)
;; Much more focussed than Vim's `listchars' variable.  I often only
;; want to see trailing whitespace anyway.
(customize-set-variable 'show-trailing-whitespace t)
(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'prog-mode-hook #'flyspell-prog-mode)
(recentf-mode)
(customize-set-variable 'recentf-max-saved-items 200)
(customize-set-variable 'recentf-max-menu-items 15)

;; From https://blog.sumtypeofway.com/posts/emacs-config.html

(customize-set-variable 'save-interprogram-paste-before-kill t)
(delete-selection-mode)
(global-so-long-mode)

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
(use-package olivetti
  :ensure t
  :preface
  (defun my/reading-mode ()
    "Toggle modes that allow for nicer reading.

Currently `olivetti-mode' and `display-line-numbers-mode'."
    (interactive)
    (require 'olivetti)
    (if olivetti-mode
	(progn
	  (olivetti-mode -1)
	  (display-line-numbers-mode 1)
	  (diff-hl-mode 1)
	  ;; Ensure the highlighting comes back immediately.
	  (diff-hl-update)
	  (setq show-trailing-whitespace t))
      (olivetti-mode 1)
      (display-line-numbers-mode -1)
      (diff-hl-mode -1)
      (setq show-trailing-whitespace nil)))
  :bind ("<f6>" . my/reading-mode))

(defun my/confirm-print (fun &rest args)
  "Confirm whether to actually print, applying FUN to the arg list ARGS if confirmed.

I've been bitten a couple times before: no more."
  (when (yes-or-no-p "Print? ")
    (apply fun args)))
(use-package ibuffer
  :config
  (advice-add 'ibuffer-do-print :around #'my/confirm-print)
  :bind (("C-x C-b" . ibuffer)))
(use-package dired
  :custom
  ;; Human-readable file sizes.
  (dired-listing-switches "-alh")
  (dired-dwim-target t)
  :config
  (advice-add 'dired-do-print :around #'my/confirm-print))
(use-package dired-x
  :custom
  (dired-x-hands-off-my-keys nil))

(use-package imenu
  :custom
  (imenu-auto-rescan t))
(customize-set-variable 'isearch-lazy-count t)

(use-package scratch
  :ensure t
  :bind (("C-c s" . scratch)))
(use-package simple
  :bind (;; Cases
	 ("M-u" . upcase-dwim)
	 ("M-l" . downcase-dwim)
	 ("M-c" . capitalize-dwim)
	 ;; Buffers
	 ("H-n H-n" . clone-buffer)
	 ("H-n n" . clone-indirect-buffer)
	 ("C-x k" . kill-current-buffer)))
(use-package help-mode
  :hook (help-mode . my/reading-mode)
  :bind (:map help-mode-map
	      ("M-n" . forward-button)
	      ("M-p" . backward-button)))
(use-package helpful
  :ensure t
  :bind (("C-h f" . helpful-callable)
	 ("C-h v" . helpful-variable)
	 ("C-h k" . helpful-key)
	 :map helpful-mode-map
	 ("M-n" . forward-button)
	 ("M-p" . backward-button)))

(use-package info
  :hook (Info-mode . my/reading-mode)
  :bind (:map Info-mode-map
	      ("M-n" . Info-next-reference)
	      ("M-p" . Info-prev-reference)))
(use-package man
  :hook (Man-mode . my/reading-mode))
(use-package woman
  :hook (woman-mode-hook . my/reading-mode))

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
  (corfu-popupinfo-hide nil) ;; Keep popup shown while scrolling between candidates
  (corfu-popupinfo-delay t)  ;; Update popup instantly
  :config
  ;; From corfu manual.
  (defun corfu-move-to-minibuffer ()
    "Transfer completion to the minibuffer.
Uses `consult-completion-in-region'."
    (interactive)
    (require 'consult)
    (let ((completion-extra-properties corfu--extra)
          completion-cycle-threshold
	  completion-cycling)
      (apply #'consult-completion-in-region completion-in-region--data)))
  :bind (:map corfu-map
	      ("M-m" . #'corfu-move-to-minibuffer)
	      ("M-q" . #'corfu-quick-complete)
	      ("C-q" .  #'corfu-quick-insert))
  ;; Enable Corfu only for certain modes.
  ;; :hook ((prog-mode . corfu-mode)
  ;;        (shell-mode . corfu-mode)
  ;;        (eshell-mode . corfu-mode))
  ;; Enable in any minibuffer as long as no other completion UI is active.  From README.
  :hook ((minibuffer-setup . (lambda ()
			       "Enable Corfu in the minibuffer if Vertico is not active."
			       (unless (bound-and-true-p vertico--input)
				 ;; (setq-local corfu-auto nil) Enable/disable auto completion
				 (corfu-mode 1))))
	 (corfu-mode . corfu-popupinfo-mode)))

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

;; From completion module of crafted-emacs.
(use-package cape
  :ensure t
  :config
  ;; Add useful defaults completion sources from cape
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-keyword)
  ;; Silence the pcomplete capf, no errors or messages!
  ;; Important for corfu
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-silent)
  ;; Ensure that pcomplete does not write to the buffer
  ;; and behaves as a pure `completion-at-point-function'.
  (advice-add 'pcomplete-completions-at-point :around #'cape-wrap-purify)
  (add-hook 'eshell-mode-hook
            (lambda ()
	      (setq-local corfu-quit-at-boundary t
			  corfu-quit-no-match t
			  corfu-auto nil)
              (corfu-mode)))
  :bind (("M-/" . cape-dabbrev)
	 ("H-c H-l" . cape-line)
	 ("H-c H-s" . cape-ispell)
	 ("H-c H-w" . cape-dict)
	 ("H-c H-f" . cape-file)
	 ("H-c H-h" . cape-history)))

(customize-set-variable 'read-file-name-completion-ignore-case t)
(customize-set-variable 'read-buffer-completion-ignore-case t)

(use-package consult
  :ensure t
  :bind (("M-X" . consult-mode-command)
         ("H-k" . consult-kmacro)
	 ("C-h M" . consult-man)
         ;; C-x bindings (ctl-x-map)
         ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer) ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)	;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer) ;; orig. project-switch-to-buffer
         ;; ;; Custom M-# bindings for fast register access
         ;; ("M-#" . consult-register-load)
         ;; ("M-'" . consult-register-store) ;; orig. abbrev-prefix-mark (unrelated)
         ;; ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)	;; orig. yank-pop
         ("<help> a" . consult-apropos)	;; orig. apropos-command
         ;; M-g bindings (goto-map)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake) ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)	 ;; orig. goto-line
         ("M-g M-g" . consult-goto-line) ;; orig. goto-line
         ("M-g o" . consult-outline) ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
	 ;; goto-map is pretty sensible.  I'm a bit used to H-{,M-}i already though.
         ("H-i" . consult-imenu)
	 ("H-M-i" . consult-imenu-multi)
	 ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings (search-map)
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ;; ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s m" . consult-multi-occur)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history) ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history) ;; orig. isearch-edit-string
         ("M-s l" . consult-line) ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)	;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history) ;; orig. next-matching-history-element
         ("M-r" . consult-history)
	 ))
(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file)))

(use-package pdf-tools
  :ensure t
  :custom
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-view-program-list '(("PDF Tools" TeX-pdf-tools-sync-view)))
  (TeX-source-correlate-start-server t)
  :config
  (pdf-tools-install)
  ;; Autorevert might not work reliably with (La)TeX.  See https://pdftools.wiki/24b671c6
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)
  (add-hook 'pdf-tools-enabled-hook #'pdf-outline-imenu-enable))
(use-package latex
  :ensure auctex
  :custom
  (TeX-auto-save t)
  (TeX-parse-self t)
  ;; Uncomment if I start using \include or \input a lot.  From Info manual.
  ;;(TeX-master nil)
  ;; Just save whenever I initiate a compile.
  ;; From https://stevelosh.com/blog/2010/09/coming-home-to-vim/ linked to by https://www.reddit.com/r/emacs/comments/5pynxg/comment/dcvu8xa/?utm_source=share&utm_medium=web2x&context=3.
  (TeX-save-query nil)
  :config
  ;; From crafted-emacs.
  ;; set a correct indentation in a few additional environments
  (add-to-list 'LaTeX-indent-environment-list '("lstlisting" current-indentation))
  (add-to-list 'LaTeX-indent-environment-list '("tikzcd" LaTeX-indent-tabular))
  (add-to-list 'LaTeX-indent-environment-list '("tikzpicture" current-indentation))

  ;; add a few macros and environment as verbatim
  (add-to-list 'LaTeX-verbatim-environments "lstlisting")
  (add-to-list 'LaTeX-verbatim-environments "Verbatim")
  (add-to-list 'LaTeX-verbatim-macros-with-braces "lstinline")
  (add-to-list 'LaTeX-verbatim-macros-with-delims "lstinline")

  ;; electric pairs in auctex
  (customize-set-variable 'TeX-electric-sub-and-superscript t)
  ;; Electric-pair-mode already does this though?
  ;; (customize-set-variable 'LaTeX-electric-left-right-brace t)
  (customize-set-variable 'TeX-electric-math (cons "$" "$"))

  ;; open all buffers with the math mode and auto-fill mode
  ;; I hate auto-fill mode in LaTeX.
  ;; (add-hook 'LaTeX-mode-hook #'auto-fill-mode)
  (add-hook 'LaTeX-mode-hook #'LaTeX-math-mode)
  (add-hook 'LaTeX-mode-hook #'outline-minor-mode)

  ;; add support for references
  (add-hook 'LaTeX-mode-hook 'turn-on-reftex)
  (customize-set-variable 'reftex-plug-into-AUCTeX t)

  ;; Synctex.
  (TeX-source-correlate-mode))

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
  (aw-dispatch-always t)
  :config
  (defun my/ensure-correct-buffer-switcher (fun &rest args)
    (require 'consult)
    (let ((switch-to-buffer #'consult-buffer))
      (funcall-interactively fun args)))
  (advice-add 'ace-window :around #'my/ensure-correct-buffer-switcher)
  ;; The default command bound to M-SPC (just-one-space) is pretty useless.
  :bind ("M-SPC" . ace-window))
(use-package tab-bar
  ;; Analogy with Isearch.
  :bind ("C-x t C-s" . tab-bar-select-tab-by-name))
(use-package emacs
  ;; Switch the current buffer to the next/previous one *based on the current window's history*.
  :bind (("H-l" . previous-buffer)
	 ("H-r" . next-buffer)
	 ("H-<left>" . shrink-window-horizontally)
	 ("H-<right>" . enlarge-window-horizontally)
	 ("H-<up>" . enlarge-window)
	 ("H-<down>" . shrink-window)))

(use-package project
  :ensure t
  :config
  ;; Modelled after project-vc-dir.
  (defun my/project-git-dir ()
    "Run Magit-Status in the current project's root."
    (interactive)
    (magit-status (project-root (project-current t))))
  (add-to-list 'project-switch-commands '(my/project-git-dir "Magit-Status"))
  :bind (("C-x p v" . my/project-git-dir)
	 ;; If I want actual vc dir.
	 ("C-x p V" . project-vc-dir)
	 ;; Easier to remember: Just prefix M-x with C-x p.
	 ("C-x p M-x" . project-execute-extended-command)))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md$" . gfm-mode))

(use-package winner
  :init
  (winner-mode)
  :custom
  (winner-dont-bind-my-keys t)
  :bind (:map winner-mode-map
	      ("H-[" . winner-undo)
	      ("H-]" . winner-redo)))

(use-package embark
  :ensure t
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  :bind* (("C-." . embark-act)
	  ("M-." . embark-dwim)
	  ("C-h B" . embark-bindings)))
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :demand t  ; only necessary if you have the hook below
  ;; if you want to have consult previews as you move around an
  ;; auto-updating embark collect buffer
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(require 'org-tempo)

(customize-set-variable 'enable-recursive-minibuffers t)
(minibuffer-depth-indicate-mode)
