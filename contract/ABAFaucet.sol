import React, { useEffect } from "react";
import {
  Grid,
  Paper,
  Button,
  TextField,
  InputAdornment,
  Typography
} from "@mui/material";
import { CurrencyBitcoinSharp } from "@mui/icons-material";
import { contractABI, contractAddress } from "./utils/contract";
import { ethers } from "ethers";

export const Faucet = () => {
  const [address, setAddress] = React.useState("");
  const [amount, setAmount] = React.useState(0);
  const [contract, setContract] = React.useState(null);
  const [balance, setBalance] = React.useState(0);
  const [isDonate, setIsDonate] = React.useState(false);
  const [latestTx, setLatestTx] = React.useState([]);

  const { ethereum } = window;

  useEffect(() => {
    connectToMetamask();
    getContract();
  }, []);

  useEffect(() => {
    if (contract) {
      getBalance();
      contract.on("Request", requestTxEvent);
      contract.on("Donate", donateTxEvent);
    }
  }, [contract]);

  const requestTxEvent = (to, amount) => {
    getBalance();
    setLatestTx([{ to, amount, type: "Request" }, ...latestTx]);
  };

  const donateTxEvent = (to, amount) => {
    getBalance();
    setLatestTx([{ to, amount, type: "Donate" }, ...latestTx]);
  };

  const connectToMetamask = async () => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    await provider.send("eth_requestAccounts", []);
  };

  const getContract = async () => {
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, contractABI, signer);
    setContract(contract);
  };

  const handleAddressInput = (evt) => {
    setAddress(evt.target.value);
  };

  const handleAmountInput = (evt) => {
    setAmount(evt.target.value);
  };

  const handleSend = async () => {
    if (isDonate) {
      await contract?.donate(amount * 100000);
      return;
    }

    if (address !== "" && address.length > 41) {
      await contract?.requestTokens();
      getBalance();
    }
  };

  const getBalance = async () => {
    let balance = await contract?.getBalance();
    setBalance(Number(balance));
  };

  return (
    <Paper elevation={2} className="bg-gradient">
      <Grid mt={2} justifyContent="flex-end" container>
        <Button variant="outlined" onClick={() => setIsDonate(!isDonate)}>
          {isDonate ? "Request" : "Donate"}
        </Button>
      </Grid>

      <Grid pt={2}>
        <Typography color="primary.dark">Total Faucet Balance</Typography>
        <Typography> {balance} ABA</Typography>
      </Grid>

      <Grid
        p={2}
        spacing={2}
        justifyContent="center"
        alignItems="center"
        container
      >
        <Grid item>
          <TextField
            size="small"
            placeholder="Wallet Address (0x...)"
            variant="outlined"
            onChange={handleAddressInput}
            InputProps={{
              endAdornment: (
                <InputAdornment position="start">
                  <CurrencyBitcoinSharp />
                </InputAdornment>
              )
            }}
          />

          {isDonate && (
            <TextField
              size="small"
              placeholder="amount x100.000"
              variant="outlined"
              type="number"
              onChange={handleAmountInput}
            />
          )}
        </Grid>
        <Grid item>
          {!isDonate ? (
            <Button variant="contained" onClick={handleSend}>
              Send Me ABA
            </Button>
          ) : (
            <Button variant="contained" onClick={handleSend}>
              Donate ABA
            </Button>
          )}
        </Grid>
      </Grid>

      <Grid pt={3} pb={6}>
        <Typography color="primary.dark">Latest Transactions</Typography>
        {latestTx.map((tx) => (
          <Paper key={tx.to + tx.from} p={3}>
            <Typography> {tx.type} </Typography>
            {!isDonate ? (
              <Typography> To: {tx.to} </Typography>
            ) : (
              <Typography> From: {tx.from} </Typography>
            )}
            <Typography> {Number(tx.amount)} ABA</Typography>
          </Paper>
        ))}
      </Grid>
    </Paper>
  );
};
