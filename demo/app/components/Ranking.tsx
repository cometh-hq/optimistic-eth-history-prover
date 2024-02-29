import { Grid } from "@mui/material";
import { shortenEthAddress } from "../lib/utils/utils";

function Ranking(): JSX.Element {
  const Array = [
    {
      position: 1,
      txNumber: 10,
      address: shortenEthAddress("0x5098197f5a517391fe67a3e22bd9c3760efa4909"),
    },
    {
      position: 2,
      txNumber: 3,
      address: shortenEthAddress("0x5098197f5a517391fe67a3e22bd9c3760efa4909"),
    },
    {
      position: 3,
      txNumber: 5,
      address: shortenEthAddress("0x5098197f5a517391fe67a3e22bd9c3760efa4909"),
    },
  ];

  return (
    <Grid container spacing={2}>
      <Grid container spacing={2}>
        <Grid item sx={{ border: "1px solid black" }} xs={4}>
          Position
        </Grid>
        <Grid item sx={{ border: "1px solid black" }} xs={4}>
          number of Tx
        </Grid>
        <Grid item sx={{ border: "1px solid black" }} xs={4}>
          Address
        </Grid>
      </Grid>
      {Array.map((row) => {
        return (
          <Grid key={row.position} container spacing={2}>
            <Grid item sx={{ border: "1px solid black" }} xs={4}>
              {row.position}
            </Grid>
            <Grid item sx={{ border: "1px solid black" }} xs={4}>
              {row.txNumber}
            </Grid>
            <Grid item sx={{ border: "1px solid black" }} xs={4}>
              {row.address}
            </Grid>
          </Grid>
        );
      })}
    </Grid>
  );
}
export default Ranking;
