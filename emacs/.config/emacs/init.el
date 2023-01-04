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
(add-hook 'special-mode-hook (lambda () (setq-local show-trailing-whitespace nil)))
(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'prog-mode-hook #'flyspell-prog-mode)
(recentf-mode)
(customize-set-variable 'recentf-max-saved-items 200)
(customize-set-variable 'recentf-max-menu-items 15)

;; Make backups of files even when under version control.
(customize-set-variable 'vc-make-backup-files t)

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

(defun my/push-mark-advice (&rest args)
  "Push current location onto mark ring as an advice.

Intended to be a :before advice for functions that should set the
mark but don't.  This is needed as a separate function because
the arguments of `push-mark' aren't guaranteed to be the same as
the advised function."
  (push-mark))
(use-package info
  :config
  (advice-add 'Info-follow-nearest-node :before #'my/push-mark-advice)
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
  :init
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :bind* (("M-X" . consult-mode-command)
          ("H-k" . consult-kmacro)
	  ("C-h M" . consult-man)
          ;; C-x bindings (ctl-x-map)
          ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
          ("C-x b" . consult-buffer) ;; orig. switch-to-buffer
          ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
          ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
          ("C-x r b" . consult-bookmark) ;; orig. bookmark-jump
          ("C-x p b" . consult-project-buffer) ;; orig. project-switch-to-buffer
          ;; ;; Custom M-# bindings for fast register access
          ;; ("M-#" . consult-register-load)
          ;; ("M-'" . consult-register-store) ;; orig. abbrev-prefix-mark (unrelated)
          ;; ("C-M-#" . consult-register)
          ;; Other custom bindings
          ("M-y" . consult-yank-pop)	;; orig. yank-pop
          ("<help> a" . consult-apropos) ;; orig. apropos-command
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
          ("M-s L" . consult-line-multi) ;; needed by consult-line to detect isearch
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
  (fset 'aw--switch-buffer #'consult-buffer)
  (defun my/aw-text-scale-reset (window)
    "Reset height of the default face in WINDOW."
    (aw-switch-to-window window)
    (unwind-protect
	(text-scale-increase 0)
      (aw-flip-window)))
  (defun my/aw-text-scale-increase (window)
    "Increase height of the default face in WINDOW."
    (aw-switch-to-window window)
    (unwind-protect
	(text-scale-increase text-scale-mode-step)
      (aw-flip-window)))
  (defun my/aw-text-scale-decrease (window)
    "Decrease height of the default face in WINDOW."
    (aw-switch-to-window window)
    (unwind-protect
	(text-scale-decrease text-scale-mode-step)
      (aw-flip-window)))
  (setq aw-dispatch-alist
	'((?x aw-delete-window "Delete Window")
	  (?m aw-swap-window "Swap Windows")
	  (?M aw-move-window "Move Window")
	  (?c aw-copy-window "Copy Window")
	  (?n aw-flip-window)
	  (?u aw-switch-buffer-in-window "Switch And Select Buffer Other Window")
	  (?U aw-switch-buffer-other-window "Switch Buffer Other Window")
	  (?e aw-execute-command-other-window "Execute Command Other Window")
	  (?F aw-split-window-fair "Split Fair Window")
	  (?_ aw-split-window-vert "Split Window Along Vertical Axis")
	  (?| aw-split-window-horz "Split Window Along Horizontal Axis")
	  (?o delete-other-windows "Delete Other Windows")
	  ;; TODO: Allow repeatable increasing/decreasing font size keys.
	  ;; Right now, I need to reinvoke ace-window to scale it again.
	  (?+ my/aw-text-scale-increase "Increase Text Scale Other Window")
	  (?- my/aw-text-scale-decrease "Decrease Text Scale Other Window")
	  (?= my/aw-text-scale-reset "Reset Text Scale Other Window")
	  (?T aw-transpose-frame "Transpose Frame")
	  (?? aw-show-dispatch-help)))
  ;; The default command bound to M-SPC (just-one-space) is pretty useless.
  :bind (("M-SPC" . ace-window)
	 ("M-g w" . ace-window)))
(use-package tab-bar
  :custom
  (tab-bar-tab-hints t)	;; Show tab numbers
  (tab-bar-select-tab-modifiers '(hyper))
  ;; Analogy with Isearch.
  :bind (("C-x t C-s" . tab-bar-select-tab-by-name)
	 ("M-g t" . tab-bar-select-tab-by-name)))
(use-package emacs
  ;; Switch the current buffer to the next/previous one *based on the current window's history*.
  :bind (("H-l" . previous-buffer)
	 ("H-r" . next-buffer)
	 ("H-<left>" . shrink-window-horizontally)
	 ("H-<right>" . enlarge-window-horizontally)
	 ("H-<up>" . enlarge-window)
	 ("H-<down>" . shrink-window)
	 ("C-c v" . visual-line-mode)
	 ("M-\\" . cycle-spacing)))
(use-package transpose-frame
  :ensure t
  :bind (("H-<" . rotate-frame-anticlockwise)
	 ("H->" . rotate-frame-clockwise)))

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
  :preface
  (defmacro my/embark-force-define-keymap (name doc &rest bindings)
    "Force keymap variable NAME to be defined by BINDINGS as with `embark-define-keymap'.
Since `defvar' doesn't seem to allow easy redefinition, ensure NAME is first unbound."
    (declare (indent 1))
    `(progn
       (makunbound ',name)
       (embark-define-keymap ,name ,doc ,@bindings)))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (my/embark-force-define-keymap embark-become-help-map
    "Keymap for Embark help actions."
    :parent embark-meta-map
    ("V" apropos-variable)
    ("U" apropos-user-option)
    ("C" apropos-command)
    ("v" describe-variable)
    ("f" helpful-callable)
    ("s" helpful-symbol)
    ("F" describe-face)
    ("p" describe-package)
    ("i" describe-input-method))
  ;; From https://github.com/oantolin/embark/wiki/Additional-Actions#use-embark-like-a-leader-key
  (defun embark-target-this-buffer ()
    (cons 'this-buffer (buffer-name)))
  (add-to-list 'embark-target-finders #'embark-target-this-buffer 'append)
  (add-to-list 'embark-keymap-alist '(this-buffer . this-buffer-map))
  ;; TODO: Wrap commands which operate on *files* to receive (buffer-file-name).
  (my/embark-force-define-keymap this-buffer-map
    "Commands to act on current file or buffer."
    ("l" load-file)
    ("b" byte-compile-file)
    ;; Not defined on my system.
    ;; ("S" sudo-find-file)
    ;; ("r" rename-file-and-buffer)
    ("d" diff-buffer-with-file)
    ("=" ediff-buffers)
    ("C-=" ediff-files)
    ("!" shell-command)
    ("&" async-shell-command)
    ("x" consult-file-externally)
    ("c" copy-file)
    ("k" kill-buffer)
    ("z" bury-buffer)
    ("|" embark-shell-command-on-buffer)
    ("g" revert-buffer))
  (defun embark-act-on-buffer (&optional arg)
    (interactive "P")
    (let ((embark-target-finders '(embark-target-this-buffer)))
      (embark-act arg)))
  :bind* (("C-." . embark-act)
	  ("C-M-." . embark-act-on-buffer)
	  ("M-." . embark-dwim)
	  ("H-b" . embark-become)
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

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package visual-regexp
  :ensure t
  :bind (("C-c r" . vr/replace)
	 ("C-c q" . vr/query-replace)))
(use-package org
  :custom
  (org-src-preserve-indentation t)
  (org-src-tab-acts-natively t)
  :bind (("C-c a" . org-agenda)
	 ("C-c A" . consult-org-agenda)
	 ("C-c l" . org-store-link)
	 :map org-mode-map
	 ("<C-M-return>" . org-insert-subheading)))

(use-package link-hint
  :ensure t
  :bind (("M-g u" . link-hint-open-link)
	 ("M-g U" . link-hint-open-multiple-links)))
;; TODO: Wrap avy to run (avy-pop-mark) if I pass a universal argument, i.e., {C-u H-SPC}.
(use-package avy
  :ensure t
  :custom
  (avy-all-windows 'all-frames)
  :config
  (defun avy-action-embark (pt)
    (unwind-protect
	(save-excursion
          (goto-char pt)
          (embark-act))
      (select-window
       (cdr (ring-ref avy-ring 0))))
    t)
  (setf (alist-get ?. avy-dispatch-alist) #'avy-action-embark)
  :bind (("M-g a" . avy-goto-char-timer)
	 ("H-SPC" . avy-goto-char-timer)
	 :map isearch-mode-map
	 ("M-g a" . avy-isearch)
	 ("H-SPC" . avy-isearch)))

(use-package wrap-region
  :ensure t
  :init
  (wrap-region-global-mode)
  (add-to-list 'wrap-region-except-modes 'special-mode)
  (add-to-list 'wrap-region-except-modes 'ibuffer-mode)
  (add-to-list 'wrap-region-except-modes 'org-agenda-mode)
  :config
  ;; wrap-region-add-wrappers is meant to be equivalent to doing each of them individually, but doesn't work for some reason.
  (wrap-region-add-wrapper "*" "*" "*" '(markdown-mode org-mode))
  (wrap-region-add-wrapper "_" "_" "_" '(markdown-mode org-mode))
  (wrap-region-add-wrapper "/" "/" "/" '(org-mode))
  (wrap-region-add-wrapper "=" "=" "M-=" '(org-mode))
  (wrap-region-add-wrapper "+" "+" "+" '(org-mode))
  (wrap-region-add-wrapper "~" "~" "~" '(org-mode))
  (wrap-region-add-wrapper "`" "`" "`" '(markdown-mode)))

(use-package redacted
  :ensure t
  :hook (redacted-mode . (lambda () (read-only-mode (if redacted-mode 1 -1)))))
(use-package wgrep
  :ensure t
  :bind (:map grep-mode-map
	      ("C-x C-q" . wgrep-change-to-wgrep-mode)))
(bind-key "C-x C-q" #'occur-edit-mode 'occur-mode-map)
(bind-key "C-x C-q" #'occur-cease-edit 'occur-edit-mode-map)
;; Use with firefox addon: https://addons.mozilla.org/en-US/firefox/addon/edit-with-emacs1/
(use-package edit-server
  :ensure t
  :commands edit-server-start
  :init
  (if after-init-time
      (edit-server-start)
    (add-hook 'after-init-hook #'edit-server-start))
  :config
  (setq edit-server-new-frame-alist
        '((name . "Edit with Emacs FRAME")
          (top . 200)
          (left . 200)
          (width . 80)
          (height . 25)
          (minibuffer . t)
          (menu-bar-lines . t)
          (window-system . x))))

;; Based on comint-delete-output
(defun comint-copy-or-kill-output (arg)
  "Copy or kill all output from interpreter since last input.

With no prefix argument, copy the region.
With prefix argument, kill the region.

In either case, does not delete the prompt."
  (interactive "P")
  (let ((proc (get-buffer-process (current-buffer)))
	(replacement nil)
	(inhibit-read-only t)
	(has-prefix-p (not (null arg))))
    (save-excursion
      (let ((pmark (progn (goto-char (process-mark proc))
			  (forward-line 0) ; go to 1st column
			  (point-marker))))
	;; Differentiate between prefix and no prefix.
	(if (not has-prefix-p)
	    (progn (kill-new (buffer-substring comint-last-input-end pmark))
		   (message "Copied all interpreter output since last input to kill ring"))
	  (kill-region comint-last-input-end pmark)
	  (goto-char (process-mark proc))
	  (setq replacement (concat "*** output killed ***\n"
				    (buffer-substring pmark (point))))
	  ;; Delete old prompt?
	  (delete-region pmark (point)))))
    ;; Output message and put back prompt
    (comint-output-filter proc replacement)))
(bind-key "C-c C-o" #'comint-copy-or-kill-output 'comint-mode-map)

(use-package separedit
  :ensure t
  :custom
  (separedit-preserve-string-indentation t)
  (separedit-remove-trailing-spaces-in-comment t)
  :bind (("C-c '" . separedit)))

(use-package volatile-highlights
  :ensure t
  :config
  (volatile-highlights-mode))

;; Enable some commands.  I don't want to do this for all of them yet.
(put 'narrow-to-region 'disabled nil)
