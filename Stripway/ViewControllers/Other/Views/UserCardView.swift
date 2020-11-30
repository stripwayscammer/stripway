//
//  UserCardView.swift
//  Stripway
//
//  Created by iBinh on 10/12/20.
//  Copyright © 2020 Stripway. All rights reserved.
//

import UIKit
import SDWebImage
import Closures

class UserCardView: UIView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var card: UserCard! {
        didSet {
            setupContent()
        }
    }
    
    private lazy var leftStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalCentering
        //        view.spacing = 8
        return view
    }()
    
    private lazy var rightStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalCentering
        //        view.spacing = 6
        return view
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .darkText
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .darkText
        label.font = UIFont(name: "Avenir Next", size: 16)
        return label
    }()
    private lazy var categoryLabel2: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = .darkText
        label.font = UIFont(name: "Avenir Next", size: 14)
        return label
    }()
    private lazy var instagramButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "instagram"), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.darkText, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir Next", size: 16)
        return button
    }()
    private lazy var twitterButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "twitter"), for: .normal)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.darkText, for: .normal)
        button.titleLabel?.font = UIFont(name: "Avenir Next", size: 16)
        return button
    }()
    private lazy var youtubeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "youtube"), for: .normal)
        button.setTitleColor(.darkText, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont(name: "Avenir Next", size: 16)
        return button
    }()
    private lazy var profileImageView: UIImageView = {
        let view = UIImageView()
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    func setupContent() {
        usernameLabel.text = card.name
        
        
        if let category = card.category {
            if category != "None" {
                categoryLabel.text = category
                categoryLabel2.text = category
                leftStackView.addArrangedSubview(categoryLabel)
            } else {
                categoryLabel2.text = ""
            }
            rightStackView.addArrangedSubview(categoryLabel2)
        }
        if let instagram = card.instagram {
            instagramButton.setTitle("  \(instagram)", for: .normal)
            instagramButton.onTap {
                self.openURL("https://instagram.com/\(instagram)")
            }
            leftStackView.addArrangedSubview(instagramButton)
        }
        if let tw = card.twitter {
            twitterButton.setTitle("  \(tw)", for: .normal)
            twitterButton.onTap {
                self.openURL("https://twitter.com/\(tw)")
            }
            leftStackView.addArrangedSubview(twitterButton)
        }
        if let yt = card.youtube {
            youtubeButton.setTitle("  \(yt)", for: .normal)
            youtubeButton.onTap {
                self.openURL("https://youtube.com/\(yt)")
            }
            leftStackView.addArrangedSubview(youtubeButton)
        }
        
        
        self.profileImageView.layer.cornerRadius = 50
        let transformer = SDImageResizingTransformer(size: CGSize(width: 100, height: 100), scaleMode: .fill)
        profileImageView.sd_setImage(with: URL(string: card.profilePicture), placeholderImage: nil, context: [.imageTransformer: transformer]) { (_, _, _) in
            DispatchQueue.main.async {
                self.profileImageView.layer.cornerRadius = 50
            }
        }
    }
    
    private func openURL(_ url: String) {
        let url = URL(string: url)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        addGestureRecognizer(tap)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.4)
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100).isActive = true
        container.widthAnchor.constraint(equalToConstant: 350).isActive = true
        container.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.backgroundColor = .white
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.addArrangedSubview(leftStackView)
        stackView.addArrangedSubview(rightStackView)
        
        container.addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 30).isActive = true
        stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -30).isActive = true
        stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 30).isActive = true
        stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -30).isActive = true
       
        leftStackView.addArrangedSubview(usernameLabel)

        rightStackView.addArrangedSubview(profileImageView)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.topAnchor.constraint(equalTo: rightStackView.topAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        
        
    }
    func showIn(_ view: UIView) {
        view.addSubview(self)
        frame = view.bounds
        container.frame = .zero
        container.center = view.center
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut],
                       animations: {
                        self.container.widthAnchor.constraint(equalToConstant: 350).isActive = true
                        self.container.heightAnchor.constraint(equalToConstant: 200).isActive = true
                        self.container.layoutIfNeeded()
                       },
                       completion: { (_) in
                       })
        
    }
    @objc func dismiss() {
        UIView.animate(withDuration: 0.25) {
            self.container.widthAnchor.constraint(equalToConstant: 0).isActive = true
            self.container.heightAnchor.constraint(equalToConstant: 0).isActive = true
            self.container.layoutIfNeeded()
        } completion: { (_) in
            self.removeFromSuperview()
        }
    }
}
