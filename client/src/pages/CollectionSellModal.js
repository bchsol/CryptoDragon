import React from "react";
import {
  Modal,
  Button,
  Form,
  InputGroup,
  DropdownButton,
  Dropdown,
} from "react-bootstrap";

const calculateEarnings = (price) => {
  const priceValue = parseFloat(price);
  const marketFeeRate = 0.025;

  if (!isNaN(priceValue)) {
    return (priceValue * (1 - marketFeeRate)).toFixed(10).replace(/\.?0*$/, "");
  }
  return "0";
};

const CollectionSellModal = ({
  show,
  onHide,
  price,
  handleDurationSelect,
  handlePriceChange,
  endTime,
  duration,
  listNftForAuction,
  listNftForSale,
}) => {
  const handleAuctionSell = () => listNftForAuction();
  const handleMarketSell = () => listNftForSale();

  return (
    <Modal show={show} size="lg" centered onHide={onHide}>
      <Modal.Header closeButton>
        <Modal.Title>Sell</Modal.Title>
      </Modal.Header>
      <Modal.Body>
        <Form>
          <Form.Group className="mb-3">
            <Form.Label>Price</Form.Label>
            <InputGroup>
              <Form.Control
                value={price}
                onChange={handlePriceChange}
                aria-label="Dollar amount"
                type="text"
              />
              <InputGroup.Text>Drink</InputGroup.Text>
            </InputGroup>
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Duration</Form.Label>
            <InputGroup>
              <Form.Control readOnly value={endTime} arial-label="End Time" />
              <DropdownButton
                variant="outline-secondary"
                title={duration || `Select duration`}
                id="input-group-dropdown"
                align="end"
                onSelect={handleDurationSelect}
              >
                <Dropdown.Item eventKey="1 hour">1 hour</Dropdown.Item>
                <Dropdown.Item eventKey="6 hours">6 hours</Dropdown.Item>
                <Dropdown.Item eventKey="1 day">1 day</Dropdown.Item>
                <Dropdown.Item eventKey="3 days">3 days</Dropdown.Item>
                <Dropdown.Item eventKey="7 days">7 days</Dropdown.Item>
                <Dropdown.Item eventKey="1 month">1 month</Dropdown.Item>
                <Dropdown.Item eventKey="3 months">3 months</Dropdown.Item>
                <Dropdown.Item eventKey="6 months">6 months</Dropdown.Item>
              </DropdownButton>
            </InputGroup>
          </Form.Group>

          <Form.Group className="mb-3">
            <Form.Label>Summary</Form.Label>
            <div>
              <div>Listing price : {price || "0"} Drink</div>
              <div>Market fee: 2.5%</div>
              <div>
                Total potential earnings: {calculateEarnings(price)} Drink
              </div>
            </div>
          </Form.Group>
        </Form>
      </Modal.Body>
      <Modal.Footer>
        <Button variant="outline-dark" onClick={handleAuctionSell}>
          Auction Sell
        </Button>
        <Button variant="outline-dark" onClick={handleMarketSell}>
          Market Sell
        </Button>
      </Modal.Footer>
    </Modal>
  );
};

export default CollectionSellModal;
