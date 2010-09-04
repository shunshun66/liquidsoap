(*****************************************************************************

  Liquidsoap, a programmable audio stream generator.
  Copyright 2003-2010 Savonet team

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details, fully stated in the COPYING
  file at the root of the liquidsoap distribution.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

 *****************************************************************************)

let check p =
  try
    let _ = Speex.Header.header_of_packet p in
    true
  with
    | _ -> false

let decoder os =
  let dec_p = ref None in
  let decoder = ref None in
  let com_p = ref None in
  let com = ref None in
  let fill feed =
    let dec,sample_freq,chans = 
      match !decoder with
        | None ->
           let dec_p = 
             match !dec_p with
               | None -> 
                   let packet = Ogg.Stream.get_packet os in
                   dec_p := Some packet;
                   packet
               | Some p -> p
           in
           let com_p = 
             match !com_p with
               | None ->
                   let packet = Ogg.Stream.get_packet os in
                   com_p := Some packet;
                   packet
               | Some p -> p
           in 
           let header = Speex.Header.header_of_packet dec_p in
           com := Some (Speex.Header.comments_of_packet com_p);
           let mode = header.Speex.Header.mode in
           let dec = Speex.Decoder.init mode in
           let sample_freq = header.Speex.Header.rate in
           let chans = header.Speex.Header.nb_channels in
           Speex.Decoder.set dec Speex.SPEEX_SET_SAMPLING_RATE sample_freq; 
           decoder := Some (dec,sample_freq,chans);
           dec,sample_freq,chans
        | Some (d,s,c) -> d,s,c
    in
    let len = ref 0 in
    let feed buf =
      let comments = !com in
      com := None; 
      let buf = Array.map (Array.map (fun x -> float x /. 32768.)) buf in
      len := !len + Array.length buf.(0);
      feed ((buf,sample_freq),comments)
    in
    try
      let decode dec os feed = 
        if chans = 2 then
          Speex.Decoder.decode_int_feed_stereo dec os feed
        else
          let feed x = 
            feed [|x|]
          in
          Speex.Decoder.decode_int_feed dec os feed
      in
      decode dec os feed
    with
      | Ogg.Not_enough_data ->
             if !len = 0 then
               raise Ogg.Not_enough_data
  in
  Ogg_demuxer.Audio fill

let () = Ogg_demuxer.ogg_decoders#register "speex" (check,decoder)
