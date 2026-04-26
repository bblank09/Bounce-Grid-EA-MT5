# Bounce Grid EA MT5

![Language](https://img.shields.io/badge/Language-MQL5-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-MetaTrader%205-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

> A long-only grid Expert Advisor for MT5 that adds positions as price falls
> and exits with a trailing stop once profit targets are reached.

---

## 🧠 Strategy Overview

BUYGRID opens a market buy position immediately on attachment.
If price declines by a configurable distance below the lowest open position,
the EA arms a re-entry trigger. Rather than buying blindly at the bottom,
it waits for price to bounce a defined number of points upward before
placing the next grid order — reducing the risk of entering into a 
continued freefall.

On the exit side, once any single open position reaches the profit
target distance, a trailing stop is activated for that position.
The stop follows price upward tick by tick and closes the position
only when price retraces below the trailing high by the configured
distance — locking in gains while allowing the trade room to run.

---

## ✨ Features

- 🛠️ **Pure MQL5** — built natively for MetaTrader 5, no legacy MT4 dependencies
- 🔢 **Magic number isolation** — all orders tagged with a unique magic number,
  safe to run alongside other EAs or manual trades on the same account
- 📉 **Bounce-confirmed grid re-entry** — does not average down blindly;
  requires a confirmed price bounce before adding the next position
- 📈 **Trailing entry trigger** — tracks the lowest point of the decline and
  enters only after a defined upward reversal
- 🎯 **Trailing exit** — profit target activates a dynamic trailing stop
  that moves with price and closes on retrace
- ⚙️ **Fully configurable input panel** — all distances, lot size, and
  magic number exposed as inputs; no recompilation needed
- 🚫 **No fixed stop-loss by design** — the grid structure manages
  drawdown through position averaging; see Risk Warning below
- 📋 **Structured error logging** — all trade failures print to the
  MT5 Experts log with function name, error code, and broker comment

---

## 📋 Input Parameters

| Parameter | Default | Description |
|---|---|---|
| **General Settings** | | |
| `Inp_Magic` | 696969 | Magic number — uniquely identifies this EA's orders |
| `Inp_LotSize` | 0.01 | Lot size for every order placed by the EA |
| **Entry Settings** | | |
| `Inp_BuyPoint` | 2500 | Distance in points below the lowest open position that arms the re-entry trigger |
| `Inp_TrsPoint` | 250 | Bounce distance in points that must be observed before a re-entry order is placed |
| **Exit Settings** | | |
| `Inp_TPPoint` | 2500 | Profit distance in points from a position's open price that activates the trailing stop |
| `Inp_TrsPointTP` | 250 | Trailing stop distance in points — position closes when price retraces this far from the trailing high |

---

## 🚀 Getting Started

### Requirements

- MetaTrader 5 (build 2755 or later recommended)
- An account with a broker that supports automated trading
- The `Trade.mqh` standard library (included with every MT5 installation)

### Installation

1. Download `Bounce_Grid_EA_MT5.mq5` from this repository
2. Open MetaTrader 5 and press **Ctrl+Shift+D** to open the Data Folder
3. Navigate to `MQL5 / Experts` and paste the file there
4. Return to MT5, open the **Navigator** panel, right-click **Expert Advisors**,
   and select **Refresh**
5. Double-click `BUYGRID` to open the input dialog
6. Configure your parameters (start with defaults on a demo account)
7. Ensure **AutoTrading** is enabled in the MT5 toolbar, then click **OK**

---

## ⚙️ How It Works

### Initial Entry
The moment the EA is attached to a chart and initialises successfully,
it places one market buy order at the current ask price using the
configured lot size. No indicator signal is required — the EA is
always in a long position when active.

### Grid Re-entry
The EA continuously tracks the lowest open price among all its
positions. When the current ask price falls more than `Inp_BuyPoint`
points below that lowest entry, the re-entry system arms itself.
From that point, the EA tracks the ask price and records the lowest
point reached. Once price bounces upward by `Inp_TrsPoint` points
from that low, a new market buy order is placed. This bounce
confirmation prevents entering into a continued downtrend. The
system then resets, ready to arm again if price falls further.

### Trailing Exit
The EA scans all open buy positions on every tick. The first position
found to be `Inp_TPPoint` points in profit (measured from its open
price to the current bid) triggers the trailing exit phase for that
specific position. A trailing stop level is calculated as `Inp_TrsPointTP`
points below the current bid, and this level only ever moves up —
never down. When the bid price falls below the trailing stop level,
the position is closed at market. After closure the trailing exit
resets and can activate again on the next qualifying position.

---

## ⚠️ Risk Warning

**This EA carries significant risk. Please read before running on a live account.**

- Past performance of any trading strategy does not guarantee future results
- This EA uses **no fixed stop-loss**. In a prolonged downtrend, open
  positions will accumulate and drawdown can be substantial
- Grid strategies can suffer large floating losses before recovering —
  ensure your account has sufficient free margin at all times
- Always test on a **demo account** with your broker's specific
  symbol and spread conditions before any live deployment
- The author accepts no responsibility for financial losses resulting
  from the use of this software

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
You are free to use, modify, and distribute this code with attribution.

---

## 🙋 Author

**[Your Name]** — MQL5 Developer
GitHub: [https://github.com/your-username](https://github.com/your-username)

*Contributions, issues, and feature requests are welcome.*
*If this project helped you, consider leaving a ⭐ on the repository.*
