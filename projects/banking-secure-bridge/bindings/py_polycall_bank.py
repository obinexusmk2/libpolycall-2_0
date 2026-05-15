"""SQUARE binding example: symmetric typed request/response over libpolycall."""
from dataclasses import dataclass

@dataclass
class Transaction:
    account_id: str
    amount: float


def submit(tx: Transaction) -> dict:
    return {"guid": "seeded-guid-demo", "status": "accepted", "amount": tx.amount}


if __name__ == "__main__":
    print(submit(Transaction("A-100", 120.50)))
