import React, { useState, useEffect } from "react";
import ToastMessage from "./ToastMessage";
import { Button, Modal, DatePicker, Tabs, Input, Tooltip, InputNumber, Select } from 'antd';
import { InfoCircleOutlined, AppleOutlined } from '@ant-design/icons';


const Consumer = ({ web3Config }) => {

  const [FoodName, setFoodName] = useState("");
  const [lotNumber, setLotNumber] = useState(0);
  const [quantity, setQuantity] = useState(0);
  const [FoodAddress, setFoodAddress] = useState("");

  const [account, setAccount] = useState(0);
  const [verifyFoodName, setverifyFoodName] = useState("");
  const [verifyFoodLot, setverifyFoodLot] = useState("");
  const [verifyFoodAddress, setverifyFoodAddress] = useState("");

  const [tokenQuantity, setTokenQuanity] = useState("");


  const [returnFoodName, setReturnFoodName] = useState("");
  const [returnLotNumber, setReturnLotNumber] = useState(0);
  const [returnQuantity, setReturnQuantity] = useState(0);
  const [returnFoodAddress, setReturnFoodAddress] = useState("");

  const [open, setOpen] = useState(false);
  const [confirmLoading, setConfirmLoading] = useState(false);
  const [modalText, setModalText] = useState('Content of the modal');
  useEffect(() => {
    showModal();
  }, []);
  const showModal = () => {
    setOpen(true);
  };

  const handleOk = () => {
    setModalText('The modal will be closed after two seconds');
    setConfirmLoading(true);
    setTimeout(() => {
      setOpen(false);
      setConfirmLoading(false);
    }, 2000);
  };
  const handleCancel = () => {
    console.log('Clicked cancel button');
    setOpen(false);
  };

  const purchaseFromFood= async () => {

    if (!FoodName || lotNumber <= 0 || quantity <= 0 || !FoodAddress) {
      ToastMessage("Failed", "Please fill in all fields", "error");
      return;
    }
    const receipt = await web3Config.consumerContract.methods
      .purchaseFood(FoodName, lotNumber, quantity, FoodAddress)
      .send({ from: web3Config.account });
    if (receipt.status) {
      ToastMessage("Sucess", "Food Purchased from Food", "success");
    } else {
      ToastMessage("Failed", "Food not Purchased from Food", "error");
    }
  };

  const verifyFood = async () => {
    if (!verifyFoodName || verifyFoodLot <= 0 || !verifyFoodAddress) {
      ToastMessage("Failed", "Please fill in all fields", "error");
      return;
    }

    const receipt = await web3Config.consumerContract.methods
      .verifyFood(verifyFoodName, verifyFoodLot, verifyFoodAddress)
      .call();
      console.log(receipt)
    if (receipt.status) {
      ToastMessage("Sucess", "Food Verified", "success");
    } else {
      ToastMessage("Failed", "Food not Verified", "error");
    }
  };

  const purchaseTokens = async () => {

    if (tokenQuantity <= 0) {
      ToastMessage("Failed", "Please enter a valid quantity", "error");
      return;
    }
    const receipt = await web3Config.consumerContract.methods.purchaseTokens(tokenQuantity).send({from: web3Config.account, value: tokenQuantity });
    if (receipt.status) {
      ToastMessage("Sucess", "Token Purchased", "success");
    } else {
      ToastMessage("Failed", "Token not Purchased", "error");
    }
  };

  const returnFoodtoFood= async () => {
    if (!returnFoodName || returnLotNumber <= 0 || returnQuantity <= 0 || !returnFoodAddress) {
      ToastMessage("Failed", "Please fill in all fields", "error");
      return;
    }

    const receipt = await web3Config.consumerContract.methods
      .returnFood(returnFoodName, returnLotNumber, returnQuantity, returnFoodAddress)
      .send({ from: web3Config.account });
  };


  //Sell Tokens
  const sellToken = async () => {
    if (account <= 0) {
      ToastMessage("Failed", "Please enter a valid account number", "error");
      return;
    }
    const sellToken = await web3Config.consumerContract.methods.sellTokens(account).send({ from: web3Config.account });
    if (sellToken.status) {
      ToastMessage("Sucess", "Distributor Valid", "success");
    } else {
      ToastMessage("Failed", "Distributor not Valid", "error");
    }
  }


  
  return (
    <div>
      <Modal
        title="Customer"
        open={open}
        onOk={handleOk}
        confirmLoading={confirmLoading}
        onCancel={handleCancel}
        okButtonProps={{ style: { backgroundColor: '#4096ff', borderColor: '#4096ff80', color: '#FFFFFF' } }}
      >  <Tabs defaultActiveKey="1">
          <Tabs.TabPane tab="Purchase Food" key="1"><div>
            <Input className="mb-2" type="text"

              value={FoodName}
              onChange={(e) => setFoodName(e.target.value)}
              placeholder="Enter Food Name"

              prefix={<AppleOutlined className="site-form-item-icon" />}
              suffix={
                <Tooltip title="Food name that help user to identify product">
                  <InfoCircleOutlined
                    style={{
                      color: 'rgba(0,0,0,.45)',
                    }}
                  />
                </Tooltip>
              }
            />

            <InputNumber className="mb-2" type="number"
              placeholder="Lot Number"
              value={lotNumber}
              onChange={value => setLotNumber(value)} addonBefore="Lot #" />

            <InputNumber className="mb-2" type="number"
              placeholder="Quantity"
              value={quantity}
              onChange={value => setQuantity(value)} addonBefore="Quantity" />

            <Input className="mb-2" type="text"
              placeholder="FoodAddress"
              value={FoodAddress}
              onChange={(e) => setFoodAddress(e.target.value)} addonBefore="Acc #" />

            <Button type="dashed" onClick={purchaseFromFood} danger> Purchase Food
            </Button></div>   </Tabs.TabPane>
          <Tabs.TabPane tab="Verify Food" key="2"><div>
            <Input className="mb-2" type="text"

              value={verifyFoodName}
              onChange={(e) => setverifyFoodName(e.target.value)}
              placeholder="Enter Food Name"

              prefix={<AppleOutlined className="site-form-item-icon" />}
              suffix={
                <Tooltip title="Food name that help user to identify product">
                  <InfoCircleOutlined
                    style={{
                      color: 'rgba(0,0,0,.45)',
                    }}
                  />
                </Tooltip>
              }
            />

            <InputNumber className="mb-2" type="number"
              placeholder="Lot Number"
              value={verifyFoodLot}
              onChange={value => setverifyFoodLot(value)} addonBefore="Lot #" />
           
            <Input className="mb-2" 
              placeholder="FoodAddress"
              value={verifyFoodAddress}
              onChange={(e) => setverifyFoodAddress(e.target.value)}  />

            <Button type="dashed" onClick={verifyFood} danger> Verify Food
            </Button></div>    </Tabs.TabPane>


          <Tabs.TabPane tab="Purchase Tokens" key="3">  <div>
            <InputNumber className="mb-2" type="number"
              placeholder="Quantity"
              value={tokenQuantity}
              onChange={value => setTokenQuanity(value)} addonBefore="Quantity" />
            <Button type="dashed" onClick={purchaseTokens} danger> Purchase Tokens
            </Button></div>  </Tabs.TabPane>
          <Tabs.TabPane tab="Return Food" key="4">  <div>

            <Input className="mb-2" type="text"

              value={returnFoodName}
              onChange={(e) => setReturnFoodName(e.target.value)}
              placeholder="Enter Food Name"

              prefix={<AppleOutlined className="site-form-item-icon" />}
              suffix={
                <Tooltip title="Food name that help user to identify product">
                  <InfoCircleOutlined
                    style={{
                      color: 'rgba(0,0,0,.45)',
                    }}
                  />
                </Tooltip>
              }
            />

            <InputNumber className="mb-2" type="number"
              placeholder="Lot Number"
              value={returnLotNumber}
              onChange={value => setReturnLotNumber(value)} addonBefore="Lot #" />

            <InputNumber className="mb-2" type="number"
              placeholder="Quantity"
              value={returnQuantity}
              onChange={value => setReturnQuantity(value)} addonBefore="Quantity" />

            <Input className="mb-2" type="text"
              placeholder="FoodAddress"
              value={returnFoodAddress}
              onChange={(e) => setReturnFoodAddress(e.target.value)}  />


            <Button type="dashed" onClick={returnFoodtoFood} danger> Return Food
            </Button></div>  </Tabs.TabPane>

          <Tabs.TabPane tab="Sell Token" key="5">
            <div>
              <Input className="mb-2" type="number" value={account} onChange={(e) => setAccount(e.target.value)} addonBefore="Token Amount" />
              <Button type="dashed" onClick={sellToken} danger>
                Sell Tokens
              </Button>
            </div>
          </Tabs.TabPane>
        </Tabs></Modal>





    </div>
  );
};

export default Consumer;
