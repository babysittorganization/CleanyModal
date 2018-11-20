//
//  CleanyAlertViewController.swift
//  CleanyModal
//
//  Created by Lory Huz on 21/03/2018.
//

import UIKit

private let kFooterMargin: CGFloat = 0
private let kCellReuseIdentifier = "actionCell"

open class CleanyAlertViewController: CleanyModalViewController {
    
    @IBOutlet private var titleLB: UILabel!
    @IBOutlet private var messageLB: UILabel!
    @IBOutlet private var actionsTV: UITableView!
    @IBOutlet public  var contentStackView: UIStackView!
    @IBOutlet private var actionsTVHeight: NSLayoutConstraint!
    @IBOutlet public  var iconIV: UIImageView!
    @IBOutlet private var bottomMarginFromActionsTV: NSLayoutConstraint!
    
    private var _textViews: [UITextView]? = nil
    open var textViews: [UITextView]? {
        get { return _textViews }
    }
    
    private var _textFields: [UITextField]? = nil
    open var textFields: [UITextField]? {
        get { return _textFields }
    }
    
    private var _actions: [CleanyAlertAction]? = nil
    fileprivate var actions: [CleanyAlertAction]? {
        get { return _actions }
    }
    
    public let data: CleanyModalBasicData
    internal var style = CleanyModalStyle(
        tintColor: UIButton.init(type: .system).titleColor(for: .normal),
        cornerRadius: 15)
    
    public init(data: CleanyModalBasicData, style: CleanyModalStyle? = nil) {
        self.data = data
        super.init(nibName: "CleanyAlertViewController", bundle: Bundle(for: CleanyAlertViewController.self))
        
        precondition(
            data.title != nil || data.message != nil, "How the fuck you would like to show an alert without at least a title OR a message ?!"
        )
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        if style != nil {
            self.style = style!
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.frame = UIScreen.main.bounds
        view.layoutIfNeeded()
        
        if self.data.title == nil {
            contentStackView.removeArrangedSubview(titleLB)
        } else if self.data.message == nil {
            contentStackView.removeArrangedSubview(messageLB)
        }
        
        titleLB.text = self.data.title
        messageLB.text = self.data.message
        iconIV.image = self.data.icon
        
        titleLB.textColor = style.textColor ?? titleLB.textColor
        titleLB.font = style.titleFont ?? titleLB.font
        
        messageLB.textColor = style.textColor ?? messageLB.textColor
        messageLB.font = style.messageFont ?? messageLB.font
        
        if self.data.icon == nil {
            iconIV.removeFromSuperview()
        }
        
        actionsTV.separatorColor = UIColor.black.withAlphaComponent(0.08)
        
        handleTableViewActions()
        applyStyle()
        
        textFields?.forEach({ textField in
            contentStackView.addArrangedSubview(textField)
            contentStackView.addConstraint(NSLayoutConstraint(
                item: textField,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: 40)
            )
        })
        
        textViews?.forEach({ textView in
            contentStackView.addArrangedSubview(textView)
            contentStackView.addConstraint(NSLayoutConstraint(
                item: textView,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: 100)
            )
        })
        
        view.layoutIfNeeded()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.layoutIfNeeded()
    }
    
    open func addAction(_ action: CleanyAlertAction) {
        if _actions == nil {
            _actions = [CleanyAlertAction]()
        }
        
        _actions?.append(action)
        
        handleTableViewActions()
    }
    
    open func replaceAction(_ action: CleanyAlertAction, atIndex index: Int) {
        _actions?[index] = action
        
        actionsTV.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
    }
    
    open func indexPathFor(cell: UITableViewCell) -> IndexPath? {
        return actionsTV.indexPath(for: cell)
    }
    
    open func addTextField(configurationHandler: ((UITextField) -> Swift.Void)? = nil) {
        if _textFields == nil {
            _textFields = [UITextField]()
        }
        
        let frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let textField = UITextField(frame: frame)
        textField.borderStyle = .none
        textField.layer.masksToBounds = true
        textField.layer.cornerRadius = 7
        textField.layer.borderColor = UIColor(white: 200.0/255.0, alpha: 1.0).cgColor
        textField.layer.borderWidth = 1
        textField.textAlignment = .center
        textField.tintColor = style.tintColor ?? UIButton.init(type: .system).titleColor(for: .normal) ?? UIColor.blue
        
        _textFields?.append(textField)
        
        configurationHandler?(textField)
    }
    
    open func addTextView(configurationHandler: ((UITextView) -> Swift.Void)? = nil) {
        if _textViews == nil {
            _textViews = [UITextView]()
        }
        
        let frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        let textView = UITextView(frame: frame)
        
        textView.layer.masksToBounds = true
        textView.layer.cornerRadius = 7
        textView.layer.borderColor = UIColor(white: 200.0/255.0, alpha: 1.0).cgColor
        textView.layer.borderWidth = 1
        textView.tintColor = style.tintColor ?? UIButton.init(type: .system).titleColor(for: .normal) ?? UIColor.blue
        
        _textViews?.append(textView)
        
        configurationHandler?(textView)
    }
    
    open func addCustomViewInContentStack(_ view: UIView) {
        contentStackView.addArrangedSubview(view)
    }
    
    // MARK: - Private methods (helpers)
    
    private func applyStyle() {
        if let cornerRadius = style.cornerRadius {
            alertView.layer.cornerRadius = cornerRadius
        }
        
        if let tintColor = style.tintColor {
            iconIV.tintColor = tintColor
        }
    }
    
    private func handleTableViewActions() {
        if viewIfLoaded != nil {
            if actionsTV.delegate == nil {
                actionsTV.dataSource = self
                actionsTV.delegate = self
                
                let bundle = Bundle(for: CleanyAlertActionTableViewCell.self)
                actionsTV.register(
                    UINib(nibName: "CleanyAlertActionTableViewCell", bundle: bundle),
                    forCellReuseIdentifier: kCellReuseIdentifier
                )
            }
            
            let count = _actions?.count ?? 0
            actionsTV.separatorStyle = _actions != nil && count > 1 ? .singleLine : .none
            
            actionsTVHeight.constant = style.actionCellHeight * CGFloat(count) + kFooterMargin
            
            if actions != nil && count > 1 {
                bottomMarginFromActionsTV.constant = 0
            }
            
            actionsTV.layoutIfNeeded()
            actionsTV.reloadData()
        }
    }
}

// MARK: - UITableView Delegates

extension CleanyAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = actions?[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier, for: indexPath) as? CleanyAlertActionTableViewCell else {
            preconditionFailure()
        }
        
        action?.cell = cell
        
        if let font = style.actionsFont {
            cell.textLabel?.font = font
        }
        
        cell.title = action?.title
        cell.img = action?.image
        
        let actionColor: UIColor!
        switch action?.style ?? .default {
        case .destructive:
            actionColor = style.destructiveColor ?? UIColor.red
        case .default:
            actionColor = style.tintColor ?? style.defaultActionColor ?? style.textColor ?? UIColor.black
        case .disabled:
            let color = style.defaultActionColor ?? style.textColor ?? UIColor.black
            actionColor = color.withAlphaComponent(0.5)
        default:
            actionColor = style.defaultActionColor ?? UIColor.black
        }
        
        cell.textLB?.textColor = actionColor
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = actionColor.withAlphaComponent(0.1)
        cell.selectedBackgroundView = selectedBackgroundView
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // flash background
        guard let action = actions?[indexPath.row] else { return }
        if action.style == .disabled || action.shouldDismissAlertOnTap == false {
            action.handler?(action)
        } else {
            self.onDismissCallback?(self)
            dismiss(animated: true) {
                action.handler?(action)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return style.actionCellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return kFooterMargin
    }
}

// MARK : - Alert action class

open class CleanyAlertAction {
    
    open var title: String?
    
    open var style: CleanyAlertActionStyle
    
    open var handler: ((CleanyAlertAction) -> Swift.Void)? = nil
    
    open var cell: UITableViewCell?
    
    open var shouldDismissAlertOnTap: Bool = true
    
    open var image: UIImage?
    
    public init(title: String?, style: CleanyAlertActionStyle, handler: ((CleanyAlertAction) -> Swift.Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

public enum CleanyAlertActionStyle: Int {
    
    case `default`
    
    case cancel
    
    case destructive
    
    case disabled
}
