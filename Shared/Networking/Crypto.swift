//
//  Crypto.swift
//  local-pal
//
//  Created by Schimweg, Luca on 26/03/2021.
//

import Foundation
import CryptoKit

enum LocalPalError : Error {
    case cryptoError
    case unknownUser
}

class LocalPalCryptoProvider {
    let privateKey: SecKey
    let publicKeyRepr: Data
    let publicKeyHash: String
    var userKeys: Dictionary<UUID, SecKey> = Dictionary()
    
    init() throws {
        let attr = [
            kSecAttrKeyType as String : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String : 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrCanDecrypt: true,
                kSecAttrIsPermanent: false,
                kSecAttrApplicationTag: "local-pal"
            ]
        ] as CFDictionary
        
        var pubKeyOpt, privKeyOpt: SecKey?
        
        SecKeyGeneratePair(attr, &pubKeyOpt, &privKeyOpt)
        
        guard let publicKey = pubKeyOpt else {
            throw LocalPalError.cryptoError
        }
        
        guard let privateKey = privKeyOpt else {
            throw LocalPalError.cryptoError
        }
        self.privateKey = privateKey
        
        var error:Unmanaged<CFError>?
        guard let cfdata = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            throw LocalPalError.cryptoError
        }
        
        self.publicKeyRepr = cfdata as Data
        
        try self.publicKeyHash = LocalPalCryptoProvider.hashKey(key: publicKey)
    }
    
    func registerUser(id userId: UUID, key publicKeyRepr: Data) {
        let attr = [
            kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass : kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits : 256,
            kSecReturnPersistentRef : false
        ] as CFDictionary
        
        var error:Unmanaged<CFError>?
        if let pubKey = SecKeyCreateWithData(publicKeyRepr as CFData, attr, &error) {
            userKeys[userId] = pubKey
        }
    }
    
    func encryptMessage(to userId: UUID, text: String) throws -> Data {
        guard let pubKey = userKeys[userId] else {
            throw LocalPalError.cryptoError
        }
        
        guard let encText = text.data(using: String.Encoding.utf8) else {
            throw LocalPalError.cryptoError
        }
        
        var error:Unmanaged<CFError>?
        guard let enc = SecKeyCreateEncryptedData(pubKey, SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM, encText as CFData, &error) else {
            throw LocalPalError.cryptoError
        }
        
        return enc as Data
    }
    
    func decryptMessage(data: Data) throws -> String {
        var error:Unmanaged<CFError>?
        guard let dec = SecKeyCreateDecryptedData(self.privateKey, SecKeyAlgorithm.eciesEncryptionStandardX963SHA256AESGCM, data as CFData, &error) else {
            throw LocalPalError.cryptoError
        }
        
        guard let decrypted = String(data: dec as Data, encoding: String.Encoding.utf8) else {
            throw LocalPalError.cryptoError
        }
        
        return decrypted
    }
    
    func usersLeave(users: [User]) {
        for user in users {
            self.userKeys.removeValue(forKey: user.uuid)
        }
    }
    
    func getPublicKeyHash(forUser userId: UUID) throws -> String {
        guard let pubKey = userKeys[userId] else {
            throw LocalPalError.cryptoError
        }
        
        return try LocalPalCryptoProvider.hashKey(key: pubKey)
    }
    
    private static func hashKey(key: SecKey) throws -> String {
        var error:Unmanaged<CFError>?
        guard let cfdata = SecKeyCopyExternalRepresentation(key, &error) else {
            throw LocalPalError.cryptoError
        }
        
        let hash = SHA256.hash(data: cfdata as Data)
        return String(hash.description.suffix(16))
    }
}
