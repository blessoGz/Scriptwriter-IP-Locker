# 📝 Scriptwriter IP Locker

A blockchain-based intellectual property protection system for scriptwriters using Stacks smart contracts. Secure your creative work with cryptographic proof of ownership and monetize through licensing.

## 🌟 Features

- 🔐 **Immutable Script Registration** - Register scripts with cryptographic hashes on-chain
- ⏰ **Timestamp Proof** - Blockchain-verified creation timestamps
- 💰 **Licensing System** - Producers pay license fees to access drafts
- 📊 **Analytics** - Track earnings, licenses, and script performance
- 🛡️ **Ownership Protection** - Cryptographic proof of authorship
- 🎯 **Platform Fees** - Configurable revenue sharing model

## 🚀 Quick Start

### For Scriptwriters

1. **Register Your Script**
   ```clarity
   (register-script 
     "My Amazing Screenplay" 
     "A thrilling adventure story" 
     0x1234567890abcdef... 
     u5000000)
   ```

2. **Update License Fees**
   ```clarity
   (update-license-fee script-id u10000000)
   ```

3. **Manage Script Status**
   ```clarity
   (deactivate-script script-id)
   (reactivate-script script-id)
   ```

### For Producers

1. **Purchase License**
   ```clarity
   (purchase-license script-id)
   ```

2. **Check License Status**
   ```clarity
   (has-license? script-id producer-address)
   ```

## 📖 Contract Functions

### 🔧 Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-script` | Register a new script with IP protection | `title`, `description`, `script-hash`, `license-fee` |
| `purchase-license` | Buy license to access a script | `script-id` |
| `update-license-fee` | Change licensing cost (owner only) | `script-id`, `new-fee` |
| `deactivate-script` | Temporarily disable script licensing | `script-id` |
| `reactivate-script` | Re-enable script licensing | `script-id` |

### 👀 Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-script-info` | Retrieve script details | Script metadata |
| `get-license-info` | Get license details for producer | License data |
| `has-license?` | Check if producer has license | Boolean |
| `get-scriptwriter-stats` | Get writer's performance metrics | Stats object |
| `get-producer-stats` | Get producer's licensing history | Stats object |

## 💡 Usage Examples

### 📝 Registering a Script

```clarity
;; Register a screenplay with 1 STX licensing fee
(register-script 
  "The Last Stand" 
  "Action-packed thriller set in post-apocalyptic world"
  0x8f7e6d5c4b3a29... ; SHA-256 hash of script content
  u1000000) ; 1 STX in microSTX
```

### 🎬 Purchasing a License

```clarity
;; Producer buys license for script ID 5
(purchase-license u5)
```

### 📊 Checking Statistics

```clarity
;; View scriptwriter's performance
(get-scriptwriter-stats 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Check producer's licensing history  
(get-producer-stats 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
```

## 🔒 Security Features

- **Hash Verification** - Scripts are identified by cryptographic hashes
- **Ownership Validation** - Only script owners can modify their scripts  
- **Payment Protection** - Atomic STX transfers with rollback on failure
- **Access Control** - Producer licenses are immutable once granted

## 💰 Economics

- **Minimum License Fee**: 1 STX (1,000,000 microSTX)
- **Platform Fee**: 5% (configurable by contract owner)
- **Revenue Split**: 95% to scriptwriter, 5% to platform

## 🛠️ Technical Details

- **Blockchain**: Stacks
- **Language**: Clarity
- **Storage**: On-chain maps for scripts, licenses, and statistics
- **Timestamp Method**: `stacks-block-height` and `get-stacks-block-info?`

## 🎯 Error Codes

| Code | Error | Description |
|------|--------|-------------|
| `u100` | `ERR-NOT-AUTHORIZED` | Insufficient permissions |
| `u101` | `ERR-SCRIPT-NOT-FOUND` | Script doesn't exist |
| `u102` | `ERR-ALREADY-LICENSED` | License already purchased |
| `u103` | `ERR-INSUFFICIENT-PAYMENT` | Payment too low |
| `u104` | `ERR-INVALID-SCRIPT-HASH` | Invalid hash or data |
| `u105` | `ERR-SCRIPT-ALREADY-EXISTS` | Duplicate script |
| `u106` | `ERR-INVALID-LICENSE-FEE` | Fee below minimum |
| `u107` | `ERR-TRANSFER-FAILED` | Payment transfer failed |

## 🧪 Testing

Run contract validation:
```bash
clarinet check
```

Execute test suite:
```bash
clarinet test
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

*Protect your creative work. Monetize your talent. Build on Stacks.* 🎬✨
